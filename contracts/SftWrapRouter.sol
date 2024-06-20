// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./access/GovernorControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./external/IOpenFundMarket.sol";
import "./SftWrappedTokenFactory.sol";
import "./SftWrappedToken.sol";
import "./ISftWrapRouter.sol";
import "./ISolvBTCMultiAssetPool.sol";

contract SftWrapRouter is
    ISftWrapRouter,
    ReentrancyGuardUpgradeable,
    AdminControlUpgradeable,
    GovernorControlUpgradeable
{
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
    address public sftWrappedTokenFactory;

    // sft address => sft slot => holding sft id
    mapping(address => mapping(uint256 => uint256)) public holdingSftIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address governor_, address openFundMarket_, address sftWrappedTokenFactory_)
        external
        initializer
    {
        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        GovernorControlUpgradeable.__GovernorControl_init(governor_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        openFundMarket = openFundMarket_;
        sftWrappedTokenFactory = sftWrappedTokenFactory_;
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
        require(value_ > 0, "SftWrapRouter: stake amount cannot be 0");

        IERC3525 openFundShare = IERC3525(msg.sender);
        uint256 openFundShareSlot = openFundShare.slotOf(toSftId_);

        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(
            msg.sender, openFundShareSlot
        );
        address fromSftIdOwner = openFundShare.ownerOf(fromSftId_);
        if (
            fromSftIdOwner == address(this) || fromSftIdOwner == openFundMarket || 
            fromSftIdOwner == solvBTCMultiAssetPool() || 
            (sftWrappedToken != address(0) && fromSftIdOwner == sftWrappedToken)
        ) {
            return IERC3525Receiver.onERC3525Received.selector;
        }

        {
            address toSftIdOwner = openFundShare.ownerOf(toSftId_);
            require(toSftIdOwner == address(this), "SftWrapRouter: not owned sft id");

            if (holdingSftIds[address(openFundShare)][openFundShareSlot] == 0) {
                holdingSftIds[address(openFundShare)][openFundShareSlot] = toSftId_;
            } else {
                require(
                    toSftId_ == holdingSftIds[address(openFundShare)][openFundShareSlot],
                    "SftWrapRouter: not holding sft id"
                );
            }
        }

        uint256 newSftId = IERC3525(msg.sender).transferFrom(toSftId_, address(this), value_);
        sftWrappedToken = _stakeSft(msg.sender, openFundShareSlot, newSftId, value_);
        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(fromSftIdOwner), value_);

        emit Stake(sftWrappedToken, fromSftIdOwner, address(openFundShare), openFundShareSlot, fromSftId_, value_);
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

        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(
            msg.sender, openFundShareSlot
        );

        if (
            from_ == openFundMarket || from_ == solvBTCMultiAssetPool() || 
            (sftWrappedToken != address(0) && from_ == sftWrappedToken)
        ) {
            return IERC721Receiver.onERC721Received.selector;
        }

        address sftIdOwner = openFundShare.ownerOf(sftId_);
        require(sftIdOwner == address(this), "SftWrapRouter: not owned sft id");

        uint256 openFundShareValue = openFundShare.balanceOf(sftId_);
        require(openFundShareValue > 0, "SftWrapRouter: stake amount cannot be 0");

        sftWrappedToken = _stakeSft(msg.sender, openFundShareSlot, sftId_, openFundShareValue);
        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(from_), openFundShareValue);

        emit Stake(sftWrappedToken, from_, address(openFundShare), openFundShareSlot, sftId_, openFundShareValue);
        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(address sftAddress_, uint256 sftId_, uint256 amount_) external virtual nonReentrant {
        IERC3525 sft = IERC3525(sftAddress_);
        uint256 slot = sft.slotOf(sftId_);
        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(sftAddress_, slot);
        require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");

        require(msg.sender == sft.ownerOf(sftId_), "SftWrapRouter: caller is not sft owner");
        require(amount_ > 0, "SftWrapRouter: stake amount cannot be 0");

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
            revert("SftWrapRouter: stake amount exceeds sft balance");
        }
    }

    function unstake(address swtAddress_, uint256 amount_, address sft_, uint256 slot_, uint256 sftId_)
        external
        virtual
        nonReentrant
        returns (uint256 toSftId_)
    {
        require(swtAddress_ != address(0), "SftWrapRouter: invalid swt address");
        require(amount_ > 0, "SftWrapRouter: unstake amount cannot be 0");
        ERC20TransferHelper.doTransferIn(swtAddress_, msg.sender, amount_);

        if (
            swtAddress_ == ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).solvBTC() && 
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).isSftSlotAllowed(sft_, slot_)
        ) {
            if (holdingSftIds[sft_][slot_] == 0) {
                holdingSftIds[sft_][slot_] = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).withdraw(sft_, slot_, 0, amount_);
            } else {
                ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).withdraw(sft_, slot_, holdingSftIds[sft_][slot_], amount_);
            }
        } else {
            SftWrappedToken swt = SftWrappedToken(swtAddress_);
            require(sft_ == swt.wrappedSftAddress(), "SftWrapRouter: sft address not matched");
            require(slot_ == swt.wrappedSftSlot(), "SftWrapRouter: sft slot not matched");
            require(
                swtAddress_ == SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(sft_, slot_),
                "SftWrapRouter: invalid swt address"
            );

            if (holdingSftIds[sft_][slot_] == 0) {
                holdingSftIds[sft_][slot_] = swt.burn(amount_, 0);
            } else {
                swt.burn(amount_, holdingSftIds[sft_][slot_]);
            }
        }

        if (sftId_ == 0) {
            toSftId_ = ERC3525TransferHelper.doTransferOut(sft_, holdingSftIds[sft_][slot_], msg.sender, amount_);
        } else {
            require(slot_ == IERC3525(sft_).slotOf(sftId_), "SftWrapRouter: sftId slot not matched");
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SftWrapRouter: not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, holdingSftIds[sft_][slot_], sftId_, amount_);
            toSftId_ = sftId_;
        }

        emit Unstake(swtAddress_, msg.sender, sft_, slot_, toSftId_, amount_);
    }

    function createSubscription(bytes32 poolId_, uint256 currencyAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 shareValue_)
    {
        require(checkPoolPermission(poolId_), "SftWrapRouter: pool permission denied");
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        ERC20TransferHelper.doTransferIn(poolInfo.currency, msg.sender, currencyAmount_);
        ERC20TransferHelper.doApprove(poolInfo.currency, openFundMarket, currencyAmount_);
        shareValue_ =
            IOpenFundMarket(openFundMarket).subscribe(poolId_, currencyAmount_, 0, uint64(block.timestamp + 300));

        uint256 shareCount = openFundShare.balanceOf(address(this));
        uint256 shareId = openFundShare.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(openFundShare.slotOf(shareId) == openFundShareSlot, "SftWrapRouter: incorrect share slot");
        require(openFundShare.balanceOf(shareId) == shareValue_, "SftWrapRouter: incorrect share value");

        address sftWrappedToken = _stakeSft(address(openFundShare), openFundShareSlot, shareId, shareValue_);
        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(msg.sender), shareValue_);

        emit CreateSubscription(poolId_, msg.sender, sftWrappedToken, shareValue_, poolInfo.currency, currencyAmount_);
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

        address sftWrappedToken;
        uint256 shareId;
        if (ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).isSftSlotAllowed(address(openFundShare), openFundShareSlot)) {
            sftWrappedToken = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).solvBTC();
            ERC20TransferHelper.doTransferIn(sftWrappedToken, msg.sender, redeemAmount_);
            shareId = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).withdraw(
                address(openFundShare), openFundShareSlot, 0, redeemAmount_
            );
        } else {
            sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(
                address(openFundShare), openFundShareSlot
            );
            require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");
            shareId = ISftWrappedToken(sftWrappedToken).burn(redeemAmount_, 0);
        }

        ERC3525TransferHelper.doApproveId(address(openFundShare), openFundMarket, shareId);
        IOpenFundMarket(openFundMarket).requestRedeem(poolId_, shareId, 0, redeemAmount_);

        uint256 redemptionBalance = openFundRedemption.balanceOf(address(this));
        redemptionId_ = openFundRedemption.tokenOfOwnerByIndex(address(this), redemptionBalance - 1);
        require(
            openFundRedemption.balanceOf(redemptionId_) == redeemAmount_, "SftWrapRouter: incorrect redemption value"
        );
        ERC3525TransferHelper.doTransferOut(address(openFundRedemption), payable(msg.sender), redemptionId_);

        emit CreateRedemption(poolId_, msg.sender, sftWrappedToken, redeemAmount_, redemptionId_);
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

        address sftWrappedToken = _stakeSft(address(openFundShare), openFundShareSlot, shareId, shareValue);
        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(msg.sender), shareValue);

        emit CancelRedemption(poolId_, msg.sender, sftWrappedToken, openFundRedemptionId_, shareValue);
    }

    function checkPoolPermission(bytes32 poolId_) public view virtual returns (bool) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        if (poolInfo.permissionless) {
            return true;
        }
        address whiteListManager = IOpenFundMarket(openFundMarket).getAddress("OFMWhitelistStrategyManager");
        return IOFMWhitelistStrategyManager(whiteListManager).isWhitelisted(poolId_, msg.sender);
    }

    function solvBTCMultiAssetPool() public view virtual returns (address) {
        return address(0);  // set address after SolvBTCMultiAssetPool is deployed
    }

    function _stakeSft(address sft_, uint256 slot_, uint256 sftId_, uint256 value_)
        internal virtual returns (address sftWrappedToken) 
    {
        if (ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).isSftSlotAllowed(sft_, slot_)) {
            sftWrappedToken = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).solvBTC();
            IERC3525(sft_).approve(solvBTCMultiAssetPool(), sftId_);
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool()).deposit(sft_, sftId_, value_);
        } else {
            sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(sft_, slot_);
            require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");
            IERC3525(sft_).approve(sftWrappedToken, sftId_);
            ISftWrappedToken(sftWrappedToken).mint(sftId_, value_);
        }
    }

}
