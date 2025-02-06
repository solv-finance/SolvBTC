// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./access/GovernorControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./external/IOpenFundMarket.sol";
import "./BitcoinReserveOffering.sol";
import "./ISftWrapRouter.sol";

contract BRORouter is ISftWrapRouter, ReentrancyGuardUpgradeable, AdminControlUpgradeable, GovernorControlUpgradeable {

    event CreateSubscription(
        bytes32 indexed poolId,
        address indexed subscriber,
        address sftWrappedToken,
        uint256 swtTokenAmount,
        address currency,
        uint256 currencyAmount
    );
    event CreateRedemption(
        bytes32 indexed poolId,
        address indexed redeemer,
        address indexed sftWrappedToken,
        uint256 redeemAmount,
        uint256 redemptionId
    );
    event CancelRedemption(
        bytes32 indexed poolId,
        address indexed owner,
        address indexed sftWrappedToken,
        uint256 redemptionId,
        uint256 cancelAmount
    );
    event Stake(
        address indexed sftWrappedToken,
        address indexed staker,
        address sft,
        uint256 sftSlot,
        uint256 sftId,
        uint256 amount
    );
    event Unstake(
        address indexed sftWrappedToken,
        address indexed unstaker,
        address sft,
        uint256 sftSlot,
        uint256 sftId,
        uint256 amount
    );

    address public openFundMarket;

    // sft address => sft slot => broToken address
    mapping(address => mapping(uint256 => address)) public broTokens;

    // sft address => sft slot => holding sft id
    mapping(address => mapping(uint256 => uint256)) public holdingSftIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address governor_, address openFundMarket_) external initializer {
        require(governor_ != address(0), "BRORouter: invalid governor");
        require(openFundMarket_ != address(0), "BRORouter: invalid openFundMarket");

        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        GovernorControlUpgradeable.__GovernorControl_init(governor_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        openFundMarket = openFundMarket_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return 
            interfaceId == type(IERC3525Receiver).interfaceId || 
            interfaceId == type(IERC721Receiver).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    function onERC3525Received(
        address, /* operator_ */
        uint256 fromSftId_,
        uint256 toSftId_,
        uint256 value_,
        bytes calldata /* data_ */
    ) external virtual override returns (bytes4) {
        IERC3525 openFundShare = IERC3525(msg.sender);
        uint256 openFundShareSlot = openFundShare.slotOf(toSftId_);
        address broToken = broTokens[address(openFundShare)][openFundShareSlot];
        require(broToken != address(0), "BRORouter: broToken not created");
        require(value_ > 0, "BRORouter: stake amount cannot be 0");

        address fromSftIdOwner = openFundShare.ownerOf(fromSftId_);
        if (fromSftIdOwner == openFundMarket || fromSftIdOwner == broToken) {
            return IERC3525Receiver.onERC3525Received.selector;
        }

        address toSftIdOwner = openFundShare.ownerOf(toSftId_);
        require(toSftIdOwner == address(this), "BRORouter: not owned sft id");

        if (holdingSftIds[address(openFundShare)][openFundShareSlot] == 0) {
            holdingSftIds[address(openFundShare)][openFundShareSlot] = toSftId_;
        } else {
            require(
                toSftId_ == holdingSftIds[address(openFundShare)][openFundShareSlot],
                "BRORouter: not holding sft id"
            );
        }

        {
            uint256 netBroTokenAmount;
            uint256 broTokenBalanceBefore = IERC20(broToken).balanceOf(address(this));
            uint256 swtHoldingValueSftId = BitcoinReserveOffering(broToken).holdingValueSftId();
            if (swtHoldingValueSftId == 0) {
                ERC3525TransferHelper.doTransferOut(address(openFundShare), toSftId_, broToken, value_);
            } else {
                ERC3525TransferHelper.doTransfer(address(openFundShare), toSftId_, swtHoldingValueSftId, value_);
            }
            netBroTokenAmount = IERC20(broToken).balanceOf(address(this)) - broTokenBalanceBefore;
            ERC20TransferHelper.doTransferOut(broToken, payable(fromSftIdOwner), netBroTokenAmount);
        }

        emit Stake(broToken, fromSftIdOwner, address(openFundShare), openFundShareSlot, fromSftId_, value_);
        return IERC3525Receiver.onERC3525Received.selector;
    }

    function onERC721Received(address, /* operator_ */ address from_, uint256 sftId_, bytes calldata /* data_ */ )
        external
        virtual
        override
        returns (bytes4)
    {
        IERC3525 openFundShare = IERC3525(msg.sender);
        uint256 openFundShareSlot = openFundShare.slotOf(sftId_);
        address broToken = broTokens[address(openFundShare)][openFundShareSlot];
        require(broToken != address(0), "BRORouter: broToken not created");

        if (from_ == openFundMarket || from_ == broToken) {
            return IERC721Receiver.onERC721Received.selector;
        }

        require(openFundShare.balanceOf(sftId_) > 0, "BRORouter: stake amount cannot be 0");

        address sftIdOwner = openFundShare.ownerOf(sftId_);
        require(sftIdOwner == address(this), "BRORouter: not owned sft id");

        uint256 openFundShareValue = openFundShare.balanceOf(sftId_);
        uint256 broTokenBalanceBefore = IERC20(broToken).balanceOf(address(this));
        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), broToken, sftId_);
        uint256 netBroTokenAmount = IERC20(broToken).balanceOf(address(this)) - broTokenBalanceBefore;
        ERC20TransferHelper.doTransferOut(broToken, payable(from_), netBroTokenAmount);

        emit Stake(broToken, from_, address(openFundShare), openFundShareSlot, sftId_, openFundShareValue);
        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(address sftAddress_, uint256 sftId_, uint256 amount_) external virtual nonReentrant {
        IERC3525 sft = IERC3525(sftAddress_);
        uint256 slot = sft.slotOf(sftId_);
        address broToken = broTokens[sftAddress_][slot];
        require(broToken != address(0), "BRORouter: broToken not created");

        require(msg.sender == sft.ownerOf(sftId_), "BRORouter: caller is not sft owner");
        require(amount_ > 0, "BRORouter: stake amount cannot be 0");

        uint256 sftBalance = sft.balanceOf(sftId_);
        if (amount_ == sftBalance) {
            ERC3525TransferHelper.doSafeTransferIn(sftAddress_, msg.sender, sftId_);
        } else if (amount_ < sftBalance) {
            uint256 holdingSftId = holdingSftIds[sftAddress_][slot];
            if (holdingSftId == 0) {
                ERC3525TransferHelper.doTransferIn(sftAddress_, sftId_, amount_);
            } else {
                ERC3525TransferHelper.doTransfer(sftAddress_, sftId_, holdingSftId, amount_);
            }
        } else {
            revert("BRORouter: stake amount exceeds sft balance");
        }
    }

    function unstake(address broTokenAddress_, uint256 amount_, uint256 sftId_)
        external
        virtual
        nonReentrant
        returns (uint256 toSftId_)
    {
        require(broTokenAddress_ != address(0), "BRORouter: invalid broToken address");
        BitcoinReserveOffering broToken = BitcoinReserveOffering(broTokenAddress_);
        address sftAddress = broToken.wrappedSftAddress();
        uint256 slot = broToken.wrappedSftSlot();
        require(
            broTokenAddress_ == broTokens[sftAddress][slot],
            "BRORouter: invalid sft and slot for broToken"
        );

        require(amount_ > 0, "BRORouter: unstake amount cannot be 0");
        ERC20TransferHelper.doTransferIn(broTokenAddress_, msg.sender, amount_);

        uint256 holdingSftId = holdingSftIds[sftAddress][slot];
        uint256 holdingSftValueBefore;
        if (holdingSftId == 0) {
            holdingSftId = broToken.holdingValueSftId();
            holdingSftIds[sftAddress][slot] = holdingSftId;
        } else {
            holdingSftValueBefore = IERC3525(sftAddress).balanceOf(holdingSftId);
            broToken.burn(amount_, holdingSftId);
        }

        uint256 netSftValue = IERC3525(sftAddress).balanceOf(holdingSftId) - holdingSftValueBefore;
        if (sftId_ == 0) {
            toSftId_ =
                ERC3525TransferHelper.doTransferOut(sftAddress, holdingSftId, msg.sender, netSftValue);
        } else {
            require(slot == IERC3525(sftAddress).slotOf(sftId_), "BRORouter: slot does not match");
            require(msg.sender == IERC3525(sftAddress).ownerOf(sftId_), "BRORouter: not sft owner");
            ERC3525TransferHelper.doTransfer(sftAddress, holdingSftId, sftId_, netSftValue);
            toSftId_ = sftId_;
        }

        emit Unstake(broTokenAddress_, msg.sender, sftAddress, slot, toSftId_, amount_);
    }

    function createSubscription(bytes32 poolId_, uint256 currencyAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 shareValue_)
    {
        require(checkPoolPermission(poolId_), "BRORouter: pool permission denied");
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;
        ERC20TransferHelper.doTransferIn(poolInfo.currency, msg.sender, currencyAmount_);

        ERC20TransferHelper.doApprove(poolInfo.currency, openFundMarket, currencyAmount_);
        shareValue_ =
            IOpenFundMarket(openFundMarket).subscribe(poolId_, currencyAmount_, 0, uint64(block.timestamp + 300));

        uint256 shareCount = openFundShare.balanceOf(address(this));
        uint256 shareId = openFundShare.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(openFundShare.slotOf(shareId) == openFundShareSlot, "BRORouter: incorrect share slot");
        require(openFundShare.balanceOf(shareId) == shareValue_, "BRORouter: incorrect share value");

        address broToken = broTokens[address(openFundShare)][openFundShareSlot];
        require(broToken != address(0), "BRORouter: broToken not created");

        uint256 broTokenBalanceBefore = IERC20(broToken).balanceOf(address(this));
        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), broToken, shareId);
        uint256 netBroTokenAmount = IERC20(broToken).balanceOf(address(this)) - broTokenBalanceBefore;
        ERC20TransferHelper.doTransferOut(broToken, payable(msg.sender), netBroTokenAmount);

        emit CreateSubscription(poolId_, msg.sender, broToken, shareValue_, poolInfo.currency, currencyAmount_);
    }

    function createRedemption(bytes32 poolId_, uint256 redeemAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 redemptionId_)
    {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        IERC3525 openFundRedemption = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        address broToken = broTokens[address(openFundShare)][openFundShareSlot];
        require(broToken != address(0), "BRORouter: sft wrapped token not created");
        ERC20TransferHelper.doTransferIn(broToken, msg.sender, redeemAmount_);

        uint256 shareId = ISftWrappedToken(broToken).burn(redeemAmount_, 0);
        uint256 shareValue = openFundShare.balanceOf(shareId);
        ERC3525TransferHelper.doApproveId(address(openFundShare), openFundMarket, shareId);
        IOpenFundMarket(openFundMarket).requestRedeem(poolId_, shareId, 0, shareValue);

        uint256 redemptionBalance = openFundRedemption.balanceOf(address(this));
        redemptionId_ = openFundRedemption.tokenOfOwnerByIndex(address(this), redemptionBalance - 1);
        require(
            openFundRedemption.balanceOf(redemptionId_) == shareValue, "BRORouter: incorrect redemption value"
        );
        ERC3525TransferHelper.doTransferOut(address(openFundRedemption), payable(msg.sender), redemptionId_);

        emit CreateRedemption(poolId_, msg.sender, broToken, redeemAmount_, redemptionId_);
    }

    function cancelRedemption(bytes32 poolId_, uint256 openFundRedemptionId_) external virtual nonReentrant {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        IERC3525 openFundRedemption = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        ERC3525TransferHelper.doTransferIn(address(openFundRedemption), msg.sender, openFundRedemptionId_);
        ERC3525TransferHelper.doApproveId(address(openFundRedemption), openFundMarket, openFundRedemptionId_);
        IOpenFundMarket(openFundMarket).revokeRedeem(poolId_, openFundRedemptionId_);
        uint256 shareBalance = openFundShare.balanceOf(address(this));
        uint256 shareId = openFundShare.tokenOfOwnerByIndex(address(this), shareBalance - 1);
        uint256 shareValue = openFundShare.balanceOf(shareId);

        address broToken = broTokens[address(openFundShare)][openFundShareSlot];
        require(broToken != address(0), "BRORouter: broToken not created");

        uint256 broTokenBalanceBefore = IERC20(broToken).balanceOf(address(this));
        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), broToken, shareId);
        uint256 netBroTokenAmount = IERC20(broToken).balanceOf(address(this)) - broTokenBalanceBefore;
        ERC20TransferHelper.doTransferOut(broToken, payable(msg.sender), netBroTokenAmount);

        emit CancelRedemption(poolId_, msg.sender, broToken, openFundRedemptionId_, shareValue);
    }

    function checkPoolPermission(bytes32 poolId_) public view virtual returns (bool) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        if (poolInfo.permissionless) {
            return true;
        }
        address whiteListManager = IOpenFundMarket(openFundMarket).getAddress("OFMWhitelistStrategyManager");
        return IOFMWhitelistStrategyManager(whiteListManager).isWhitelisted(poolId_, msg.sender);
    }

    uint256[47] private __gap;
}
