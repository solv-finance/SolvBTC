// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./external/IERC3525.sol";
import "./external/IOpenFundMarket.sol";
import "./ISolvBTCMultiAssetPool.sol";

contract SolvBTCMultiPoolRouter is ReentrancyGuardUpgradeable, AdminControlUpgradeable {

    event SetSolvBTCPoolIdByCurrency(address indexed currency, bytes32 indexed solvBTCPoolId);
    event CreateSubscription(
        bytes32 indexed targetPoolId,
        bytes32 indexed solvBTCPoolId,
        address indexed subscriber,
        address currency,
        uint256 currencyAmount,
        address yieldToken,
        uint256 yieldTokenAmount
    );

    address public openFundMarket;
    address public solvBTCMultiAssetPool;
    address public solvBTCYieldTokenMultiAssetPool;

    // payment currency => SolvBTC poolId
    mapping(address => bytes32) public solvBTCPoolIdByCurrency;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin_, 
        address openFundMarket_, 
        address solvBTCMultiAssetPool_,
        address solvBTCYieldTokenMultiAssetPool_
    )
        external
        initializer
    {
        require(admin_ != address(0), "SolvBTCMultiPoolRouter: invalid admin");
        require(openFundMarket_ != address(0), "SolvBTCMultiPoolRouter: invalid openFundMarket");
        require(solvBTCMultiAssetPool_ != address(0), "SolvBTCMultiPoolRouter: invalid solvBTCMultiAssetPool");
        require(solvBTCYieldTokenMultiAssetPool_ != address(0), "SolvBTCMultiPoolRouter: invalid solvBTCYieldTokenMultiAssetPool");

        AdminControlUpgradeable.__AdminControl_init(admin_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        openFundMarket = openFundMarket_;
        solvBTCMultiAssetPool = solvBTCMultiAssetPool_;
        solvBTCYieldTokenMultiAssetPool = solvBTCYieldTokenMultiAssetPool_;
    }

    function createSubscription(bytes32 targetPoolId_, address currency_, uint256 currencyAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 yieldTokenAmount_)
    {
        bytes32 solvBTCPoolId = solvBTCPoolIdByCurrency[currency_];
        require(solvBTCPoolId > 0, "SolvBTCMultiPoolRouter: invalid currency");

        ERC20TransferHelper.doTransferIn(currency_, msg.sender, currencyAmount_);
        (address solvBTC, uint256 solvBTCAmount) = _createSubscription(
            solvBTCPoolId, currency_, currencyAmount_, solvBTCMultiAssetPool
        );
        (address yieldToken, uint256 yieldTokenAmount) = _createSubscription(
            targetPoolId_, solvBTC, solvBTCAmount, solvBTCYieldTokenMultiAssetPool
        );
        ERC20TransferHelper.doTransferOut(yieldToken, payable(msg.sender), yieldTokenAmount);

        emit CreateSubscription(targetPoolId_, solvBTCPoolId, msg.sender, currency_, currencyAmount_, yieldToken, yieldTokenAmount_);
    }

    function _createSubscription(
        bytes32 poolId_, 
        address currency_, 
        uint256 currencyAmount_, 
        address multiAssetPool_
    ) 
        internal 
        returns (address receivedToken_, uint256 receivedTokenAmount_)
    {
        require(checkPoolPermission(poolId_), "SolvBTCMultiPoolRouter: pool permission denied");

        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        require(currency_ == poolInfo.currency, "SolvBTCMultiPoolRouter: currency not match");
        IERC3525 share = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 shareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        ERC20TransferHelper.doApprove(currency_, openFundMarket, currencyAmount_);
        receivedTokenAmount_ = IOpenFundMarket(openFundMarket).subscribe(
            poolId_, currencyAmount_, 0, uint64(block.timestamp + 300)
        );

        uint256 shareCount = share.balanceOf(address(this));
        uint256 shareId = share.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(shareSlot == share.slotOf(shareId), "SolvBTCMultiPoolRouter: incorrect share slot");
        require(receivedTokenAmount_ == share.balanceOf(shareId), "SolvBTCMultiPoolRouter: incorrect share value");

        share.approve(multiAssetPool_, shareId);
        ISolvBTCMultiAssetPool(multiAssetPool_).deposit(address(share), shareId, receivedTokenAmount_);

        receivedToken_ = ISolvBTCMultiAssetPool(multiAssetPool_).getERC20(address(share), shareSlot);
    }

    function checkPoolPermission(bytes32 poolId_) public view virtual returns (bool) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        if (poolInfo.permissionless) {
            return true;
        }
        address whiteListManager = IOpenFundMarket(openFundMarket).getAddress("OFMWhitelistStrategyManager");
        return IOFMWhitelistStrategyManager(whiteListManager).isWhitelisted(poolId_, msg.sender);
    }

    function setSolvBTCPoolIdByCurrency(address currency_, bytes32 solvBTCPoolId_) external virtual onlyAdmin {
        require(currency_ != address(0), "SolvBTCMultiPoolRouter: invalid currency");
        solvBTCPoolIdByCurrency[currency_] = solvBTCPoolId_;
        emit SetSolvBTCPoolIdByCurrency(currency_, solvBTCPoolId_);
    }

    uint256[46] private __gap;
}
