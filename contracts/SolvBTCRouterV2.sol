// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IOpenFundMarket, IOFMWhitelistStrategyManager, PoolInfo} from "./external/IOpenFundMarket.sol";
import {
    IOpenFundRedemptionDelegate, IOpenFundRedemptionConcrete, RedeemInfo
} from "./external/IOpenFundRedemption.sol";
import {IERC721} from "./external/IERC721.sol";
import {IERC3525} from "./external/IERC3525.sol";
import {ERC20TransferHelper} from "./utils/ERC20TransferHelper.sol";
import {ERC3525TransferHelper} from "./utils/ERC3525TransferHelper.sol";
import {ISolvBTCMultiAssetPool} from "./ISolvBTCMultiAssetPool.sol";
import {IxSolvBTCPool} from "./IxSolvBTCPool.sol";
import {FeeManager} from "./FeeManager.sol";

contract SolvBTCRouterV2 is ReentrancyGuardUpgradeable, Ownable2StepUpgradeable {
    event Deposit(
        address indexed targetToken,
        address indexed currency,
        address indexed depositor,
        uint256 targetTokenAmount,
        uint256 currencyAmount,
        address[] path,
        bytes32[] poolIds
    );
    event CollectDepositFee(
        address indexed payer,
        address indexed currency,
        address indexed feeReceiver,
        uint256 feeAmount
    );
    event WithdrawRequest(
        address indexed targetToken,
        address indexed currency,
        address indexed requester,
        bytes32 poolId,
        uint256 withdrawAmount,
        uint256 redemptionId
    );
    event CancelWithdrawRequest(
        address indexed targetToken,
        address indexed redemption,
        address indexed requester,
        bytes32 poolId,
        uint256 redemptionId,
        uint256 targetTokenAmount
    );
    event SetOpenFundMarket(address indexed openFundMarket);
    event AddKycSBTVerifier(address indexed verifier);
    event RemoveKycSBTVerifier(address indexed verifier);
    event SetPath(address indexed currency, address indexed targetToken, address[] path);
    event SetPoolId(address indexed targetToken, address indexed currency, bytes32 indexed poolId);
    event SetMultiAssetPool(address indexed token, address indexed multiAssetPool);
    event SetFeeManager(address feeManager);

    // the address of openFundMarket
    address public openFundMarket;

    // the addresses of SBTs that will be used to verify the KYC status
    address[] public kycSBTVerifiers;

    // currency => target ERC20 => path(ERC20[])
    mapping(address => mapping(address => address[])) public paths;

    // target ERC20 (SolvBTC or LSTs) => currency => poolId
    mapping(address => mapping(address => bytes32)) public poolIds;

    // ERC20 => multiAssetPool
    mapping(address => address) public multiAssetPools;

    address public feeManager;

    // use a special poolId to represent the xSolvBTC pool
    bytes32 public constant X_SOLV_BTC_POOL_ID =
        bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice RouterV2 initialization
     * @param owner_ The owner of this router
     * @param openFundMarket_ The address of openFundMarket
     */
    function initialize(address owner_, address openFundMarket_) external initializer {
        require(owner_ != address(0), "SolvBTCRouterV2: invalid admin");
        __Ownable_init_unchained(owner_);
        __ReentrancyGuard_init();
        _setOpenFundMarket(openFundMarket_);
    }

    /**
     * @notice Deposit currency and get targetToken
     * @param targetToken_ The target ERC20 token address to receive
     * @param currency_ The currency address to deposit
     * @param currencyAmount_ The amount of currency to deposit
     * @param minimumTargetTokenAmount_ The minimum acceptable return amount of target token
     * @param expireTime_ The expire time
     * @return targetTokenAmount_ The targetToken amount to receive
     */
    function deposit(address targetToken_, address currency_, uint256 currencyAmount_, uint256 minimumTargetTokenAmount_, uint64 expireTime_)
        external
        virtual
        nonReentrant
        returns (uint256 targetTokenAmount_)
    {
        require(currencyAmount_ > 0, "SolvBTCRouterV2: invalid currency amount");
        ERC20TransferHelper.doTransferIn(currency_, msg.sender, currencyAmount_);

        // collect deposit fee
        (uint256 feeAmount, address feeReceiver) = FeeManager(feeManager).getDepositFee(targetToken_, currency_, currencyAmount_);
        if (feeAmount > 0) {
            ERC20TransferHelper.doTransferOut(currency_, payable(feeReceiver), feeAmount);
            emit CollectDepositFee(msg.sender, currency_, feeReceiver, feeAmount);
        }

        address[] memory path = paths[currency_][targetToken_];
        bytes32[] memory pathPoolIds = new bytes32[](path.length + 1);
        targetTokenAmount_ = currencyAmount_ - feeAmount;
        for (uint256 i = 0; i <= path.length; i++) {
            address paidToken = i == 0 ? currency_ : path[i - 1];
            address receivedToken = i == path.length ? targetToken_ : path[i];
            bytes32 targetPoolId = poolIds[receivedToken][paidToken];
            pathPoolIds[i] = targetPoolId;
            // if the targetPoolId is the xSolvBTC pool, deposit to xSolvBTC pool
            if (targetPoolId == bytes32(X_SOLV_BTC_POOL_ID)) {
                targetTokenAmount_ = _depositToXSolvBTC(receivedToken, targetTokenAmount_);
            } else {
                targetTokenAmount_ = _deposit(receivedToken, paidToken, targetTokenAmount_, expireTime_);
            }
        }
        require(targetTokenAmount_ >= minimumTargetTokenAmount_, "SolvBTCRouterV2: target token amount not enough");
        ERC20TransferHelper.doTransferOut(targetToken_, payable(msg.sender), targetTokenAmount_);

        emit Deposit(targetToken_, currency_, msg.sender, targetTokenAmount_, currencyAmount_, path, pathPoolIds);
    }

    function _depositToXSolvBTC(address targetToken_, uint256 currencyAmount_)
        internal
        returns (uint256 targetTokenAmount_)
    {
        address xSolvBTCPool = multiAssetPools[targetToken_];
        return IxSolvBTCPool(xSolvBTCPool).deposit(currencyAmount_);
    }

    function _deposit(address targetToken_, address currency_, uint256 currencyAmount_, uint64 expireTime_)
        internal
        returns (uint256 targetTokenAmount_)
    {
        bytes32 targetPoolId = poolIds[targetToken_][currency_];
        require(targetPoolId > 0, "SolvBTCRouterV2: poolId not found");
        require(checkPoolPermission(targetPoolId), "SolvBTCRouterV2: pool permission denied");

        address _openFundMarket = openFundMarket;
        PoolInfo memory poolInfo = IOpenFundMarket(_openFundMarket).poolInfos(targetPoolId);
        require(currency_ == poolInfo.currency, "SolvBTCRouterV2: currency not match");
        IERC3525 share = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 shareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        address multiAssetPool = multiAssetPools[targetToken_];
        require(
            targetToken_ == ISolvBTCMultiAssetPool(multiAssetPool).getERC20(address(share), shareSlot),
            "SolvBTCRouterV2: target token not match"
        );

        ERC20TransferHelper.doApprove(currency_, _openFundMarket, currencyAmount_);
        targetTokenAmount_ =
            IOpenFundMarket(_openFundMarket).subscribe(targetPoolId, currencyAmount_, 0, expireTime_);

        uint256 shareCount = share.balanceOf(address(this));
        uint256 shareId = share.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(shareSlot == share.slotOf(shareId), "SolvBTCRouterV2: share slot not match");
        require(targetTokenAmount_ == share.balanceOf(shareId), "SolvBTCRouterV2: share value not match");

        share.approve(multiAssetPool, shareId);
        ISolvBTCMultiAssetPool(multiAssetPool).deposit(address(share), shareId, targetTokenAmount_);
    }

    /**
     * @notice Withdraw currency with target token from the pool
     * @param targetToken_ The target ERC20 token address to withdraw
     * @param currency_ The currency address to receive after claiming
     * @param withdrawAmount_ The amount of targetToken to withdraw
     * @return The address and ID of the redemption sft token to receive
     */
    function withdrawRequest(address targetToken_, address currency_, uint256 withdrawAmount_)
        external
        virtual
        nonReentrant
        returns (address, uint256)
    {
        bytes32 targetPoolId = poolIds[targetToken_][currency_];
        require(targetPoolId > 0, "SolvBTCRouterV2: poolId not found");

        address _openFundMarket = openFundMarket;
        PoolInfo memory poolInfo = IOpenFundMarket(_openFundMarket).poolInfos(targetPoolId);
        require(currency_ == poolInfo.currency, "SolvBTCRouterV2: currency not match");
        IERC3525 share = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        IERC3525 redemption = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
        uint256 shareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        {
            address multiAssetPool = multiAssetPools[targetToken_];
            require(
                targetToken_ == ISolvBTCMultiAssetPool(multiAssetPool).getERC20(address(share), shareSlot),
                "SolvBTCRouterV2: target token not match"
            );

            ERC20TransferHelper.doTransferIn(targetToken_, msg.sender, withdrawAmount_);
            uint256 shareId =
                ISolvBTCMultiAssetPool(multiAssetPool).withdraw(address(share), shareSlot, 0, withdrawAmount_);
            require(withdrawAmount_ == share.balanceOf(shareId), "SolvBTCRouterV2: share value not match");

            ERC3525TransferHelper.doApproveId(address(share), _openFundMarket, shareId);
            IOpenFundMarket(_openFundMarket).requestRedeem(targetPoolId, shareId, 0, withdrawAmount_);
        }

        uint256 redemptionCount = redemption.balanceOf(address(this));
        uint256 redemptionId_ = redemption.tokenOfOwnerByIndex(address(this), redemptionCount - 1);
        require(withdrawAmount_ == redemption.balanceOf(redemptionId_), "SolvBTCRouterV2: redemption value not match");
        ERC3525TransferHelper.doTransferOut(address(redemption), payable(msg.sender), redemptionId_);

        emit WithdrawRequest(targetToken_, currency_, msg.sender, targetPoolId, withdrawAmount_, redemptionId_);
        return (address(redemption), redemptionId_);
    }

    /**
     * @notice Cancel the withdraw request
     * @param targetToken_ The target ERC20 token address to receive after canceling
     * @param redemption_ The redemption sft token address
     * @param redemptionId_ The redemption sft token ID
     * @return targetTokenAmount_ The targetToken amount to receive
     */
    function cancelWithdrawRequest(address targetToken_, address redemption_, uint256 redemptionId_)
        external
        virtual
        nonReentrant
        returns (uint256 targetTokenAmount_)
    {
        bytes32 targetPoolId = _getPoolIdByRedemptionId(redemption_, redemptionId_);
        address _openFundMarket = openFundMarket;
        PoolInfo memory poolInfo = IOpenFundMarket(_openFundMarket).poolInfos(targetPoolId);
        IERC3525 share = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 shareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        address multiAssetPool = multiAssetPools[targetToken_];
        require(
            targetToken_ == ISolvBTCMultiAssetPool(multiAssetPool).getERC20(address(share), shareSlot),
            "SolvBTCRouterV2: target token not match"
        );

        targetTokenAmount_ = IERC3525(redemption_).balanceOf(redemptionId_);
        ERC3525TransferHelper.doTransferIn(redemption_, msg.sender, redemptionId_);
        ERC3525TransferHelper.doApproveId(redemption_, _openFundMarket, redemptionId_);
        IOpenFundMarket(_openFundMarket).revokeRedeem(targetPoolId, redemptionId_);
        uint256 shareCount = share.balanceOf(address(this));
        uint256 shareId = share.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(targetTokenAmount_ == share.balanceOf(shareId), "SolvBTCRouterV2: cancel amount not match");

        ERC3525TransferHelper.doApproveId(address(share), multiAssetPool, shareId);
        ISolvBTCMultiAssetPool(multiAssetPool).deposit(address(share), shareId, targetTokenAmount_);
        ERC20TransferHelper.doTransferOut(targetToken_, payable(msg.sender), targetTokenAmount_);

        emit CancelWithdrawRequest(
            targetToken_, redemption_, msg.sender, targetPoolId, redemptionId_, targetTokenAmount_
        );
    }

    /**
     * @notice Check if msg.sender is allowed to deposit to the pool
     * @param poolId_ The poolId of the pool to deposit
     */
    function checkPoolPermission(bytes32 poolId_) public view virtual returns (bool) {
        address _openFundMarket = openFundMarket;
        PoolInfo memory poolInfo = IOpenFundMarket(_openFundMarket).poolInfos(poolId_);
        if (poolInfo.permissionless) {
            return true;
        }
        address whiteListManager = IOpenFundMarket(_openFundMarket).getAddress("OFMWhitelistStrategyManager");
        return IOFMWhitelistStrategyManager(whiteListManager).isWhitelisted(poolId_, msg.sender) || checkKycSBT();
    }

    /**
     * @notice Verify the KYC status of msg.sender
     */
    function checkKycSBT() public view virtual returns (bool) {
        for (uint256 i = 0; i < kycSBTVerifiers.length; i++) {
            if (IERC721(kycSBTVerifiers[i]).balanceOf(msg.sender) > 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Add KYC SBT verifier
     * @param kycSBTVerifier_ The KYC SBT verifier address
     */
    function addKycSBTVerifier(address kycSBTVerifier_) external onlyOwner {
        require(kycSBTVerifier_ != address(0), "SolvBTCRouterV2: invalid verifier");
        kycSBTVerifiers.push(kycSBTVerifier_);
        emit AddKycSBTVerifier(kycSBTVerifier_);
    }

    /**
     * @notice Remove KYC SBT verifier
     * @param kycSBTVerifier_ The KYC SBT verifier address
     */
    function removeKycSBTVerifier(address kycSBTVerifier_) external onlyOwner {
        for (uint256 i = 0; i < kycSBTVerifiers.length; i++) {
            if (kycSBTVerifiers[i] == kycSBTVerifier_) {
                kycSBTVerifiers[i] = kycSBTVerifiers[kycSBTVerifiers.length - 1];
                kycSBTVerifiers.pop();
                emit RemoveKycSBTVerifier(kycSBTVerifier_);
                break;
            }
        }
    }

    function _getPoolIdByRedemptionId(address redemption_, uint256 redemptionId_) internal virtual returns (bytes32) {
        address redemptionConcrete = IOpenFundRedemptionDelegate(redemption_).concrete();
        uint256 redemptionSlot = IERC3525(redemption_).slotOf(redemptionId_);
        RedeemInfo memory redeemInfo = IOpenFundRedemptionConcrete(redemptionConcrete).getRedeemInfo(redemptionSlot);
        return redeemInfo.poolId;
    }

    function _setOpenFundMarket(address openFundMarket_) private {
        require(openFundMarket_ != address(0), "SolvBTCRouterV2: invalid openFundMarket");
        openFundMarket = openFundMarket_;
        emit SetOpenFundMarket(openFundMarket_);
    }

    /**
     * @notice Set the poolId for a target token and currency
     * @param targetToken_ The target ERC20 token address to receive
     * @param currency_ The currency address to deposit
     * @param poolId_ The poolId of the pool to deposit
     */
    function setPoolId(address targetToken_, address currency_, bytes32 poolId_) external onlyOwner {
        require(targetToken_ != address(0), "SolvBTCRouterV2: invalid targetToken");
        require(currency_ != address(0), "SolvBTCRouterV2: invalid currency");
        require(poolId_ > 0, "SolvBTCRouterV2: invalid poolId");

        poolIds[targetToken_][currency_] = poolId_;
        emit SetPoolId(targetToken_, currency_, poolId_);
    }

    /**
     * @notice Set the path for a target token and currency
     * @param currency_ The currency address to deposit
     * @param targetToken_ The target ERC20 token address to receive
     * @param path_ The addresses of the path tokens that indicate how to convert currency to targetToken
     */
    function setPath(address currency_, address targetToken_, address[] memory path_) external onlyOwner {
        require(currency_ != address(0), "SolvBTCRouterV2: invalid currency");
        require(targetToken_ != address(0), "SolvBTCRouterV2: invalid targetToken");
        for (uint256 i = 0; i < path_.length; i++) {
            require(path_[i] != address(0), "SolvBTCRouterV2: invalid path token");
        }

        paths[currency_][targetToken_] = path_;
        emit SetPath(currency_, targetToken_, path_);
    }

    /**
     * @notice Set the multiAssetPool/xSolvBTCPool address for a target token
     * @param token_ The target ERC20 token address
     * @param multiAssetPool_ The multiAssetPool/xSolvBTCPool address
     */
    function setMultiAssetPool(address token_, address multiAssetPool_) external onlyOwner {
        require(token_ != address(0), "SolvBTCRouterV2: invalid token");
        require(multiAssetPool_ != address(0), "SolvBTCRouterV2: invalid multiAssetPool");
        multiAssetPools[token_] = multiAssetPool_;
        emit SetMultiAssetPool(token_, multiAssetPool_);
    }

    /**
     * @notice Set the subscriptionFeeOracle address
     * @param feeManager_ The feeManager address
     */
    function setFeeManager(address feeManager_) external onlyOwner {
        require(feeManager_ != address(0), "SolvBTCRouterV2: invalid fee manager");
        feeManager = feeManager_;
        emit SetFeeManager(feeManager_);
    }

    uint256[44] private __gap;
}
