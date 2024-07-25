// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./access/GovernorControlUpgradeable.sol";
import "./utils/ERC20TransferHelper.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./external/IOpenFundMarket.sol";
import "./ISftWrapRouter.sol";
import "./ISolvBTCMultiAssetPool.sol";

contract SolvBTCRouter is
    ISftWrapRouter,
    ReentrancyGuardUpgradeable,
    AdminControlUpgradeable,
    GovernorControlUpgradeable
{
    event Stake(
        address indexed solvBTC, address indexed staker, address sft, uint256 sftSlot, uint256 sftId, uint256 amount
    );
    event Unstake(
        address indexed solvBTC, address indexed unstaker, address sft, uint256 sftSlot, uint256 sftId, uint256 amount
    );
    event CreateSubscription(
        bytes32 indexed poolId,
        address indexed subscriber,
        address solvBTC,
        uint256 subscribeAmount,
        address currency,
        uint256 currencyAmount
    );
    event CreateRedemption(
        bytes32 indexed poolId,
        address indexed redeemer,
        address indexed solvBTC,
        uint256 redeemAmount,
        uint256 redemptionId
    );
    event CancelRedemption(
        bytes32 indexed poolId,
        address indexed owner,
        address indexed solvBTC,
        uint256 redemptionId,
        uint256 cancelAmount
    );
    event SetOpenFundMarket(address indexed previousOpenFundMarket, address indexed newOpenFundMarket);
    event SetSolvBTCMultiAssetPool(
        address indexed previousSolvBTCMultiAssetPool, address indexed newSolvBTCMultiAssetPool
    );

    address public openFundMarket;
    address public solvBTCMultiAssetPool;

    // sft address => sft slot => holding sft id
    mapping(address => mapping(uint256 => uint256)) public holdingSftIds;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address governor_, address openFundMarket_, address solvBTCMultiAssetPool_)
        external
        initializer
    {
        require(governor_ != address(0), "SolvBTCRouter: invalid governor");
        require(openFundMarket_ != address(0), "SolvBTCRouter: invalid openFundMarket");
        require(solvBTCMultiAssetPool_ != address(0), "SolvBTCRouter: invalid solvBTCMultiAssetPool");

        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        GovernorControlUpgradeable.__GovernorControl_init(governor_);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _setOpenFundMarket(openFundMarket_);
        _setSolvBTCMultiAssetPool(solvBTCMultiAssetPool_);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC3525Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
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

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotDepositAllowed(
                address(openFundShare), openFundShareSlot
            ),
            "SolvBTCRouter: sft slot not allowed"
        );
        require(value_ > 0, "SolvBTCRouter: stake amount cannot be 0");

        address fromSftIdOwner = openFundShare.ownerOf(fromSftId_);
        if (
            fromSftIdOwner == openFundMarket || fromSftIdOwner == solvBTCMultiAssetPool
                || fromSftIdOwner == address(this)
        ) {
            return IERC3525Receiver.onERC3525Received.selector;
        }

        address toSftIdOwner = openFundShare.ownerOf(toSftId_);
        require(toSftIdOwner == address(this), "SolvBTCRouter: not owned sft id");

        {
            if (holdingSftIds[address(openFundShare)][openFundShareSlot] == 0) {
                holdingSftIds[address(openFundShare)][openFundShareSlot] = toSftId_;
            } else {
                require(
                    toSftId_ == holdingSftIds[address(openFundShare)][openFundShareSlot],
                    "SolvBTCRouter: not holding sft id"
                );
            }

            uint256 newSftId = openFundShare.transferFrom(toSftId_, address(this), value_);
            openFundShare.approve(solvBTCMultiAssetPool, newSftId);
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(openFundShare), newSftId, value_);
        }

        address solvBTC =
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getERC20(address(openFundShare), openFundShareSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(fromSftIdOwner), value_);

        emit Stake(solvBTC, fromSftIdOwner, address(openFundShare), openFundShareSlot, fromSftId_, value_);
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

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotDepositAllowed(
                address(openFundShare), openFundShareSlot
            ),
            "SolvBTCRouter: sft slot not allowed"
        );

        if (from_ == openFundMarket || from_ == solvBTCMultiAssetPool) {
            return IERC721Receiver.onERC721Received.selector;
        }

        address sftIdOwner = openFundShare.ownerOf(sftId_);
        require(sftIdOwner == address(this), "SolvBTCRouter: not owned sft id");

        uint256 openFundShareValue = openFundShare.balanceOf(sftId_);
        require(openFundShareValue > 0, "SolvBTCRouter: stake amount cannot be 0");

        openFundShare.approve(solvBTCMultiAssetPool, sftId_);
        ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(openFundShare), sftId_, openFundShareValue);

        address solvBTC =
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getERC20(address(openFundShare), openFundShareSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(from_), openFundShareValue);

        emit Stake(solvBTC, from_, address(openFundShare), openFundShareSlot, sftId_, openFundShareValue);
        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(address sftAddress_, uint256 sftId_, uint256 amount_) external virtual nonReentrant {
        IERC3525 openFundShare = IERC3525(sftAddress_);
        uint256 openFundShareSlot = openFundShare.slotOf(sftId_);

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotDepositAllowed(
                address(openFundShare), openFundShareSlot
            ),
            "SolvBTCRouter: sft slot not allowed"
        );

        require(msg.sender == openFundShare.ownerOf(sftId_), "SolvBTCRouter: caller is not sft owner");
        require(amount_ > 0, "SolvBTCRouter: stake amount cannot be 0");

        uint256 sftBalance = openFundShare.balanceOf(sftId_);
        if (amount_ == sftBalance) {
            ERC3525TransferHelper.doSafeTransferIn(sftAddress_, msg.sender, sftId_);
        } else if (amount_ < sftBalance) {
            uint256 holdingSftId = holdingSftIds[sftAddress_][openFundShareSlot];
            if (holdingSftId == 0) {
                ERC3525TransferHelper.doTransferIn(sftAddress_, sftId_, amount_);
            } else {
                ERC3525TransferHelper.doTransfer(sftAddress_, sftId_, holdingSftId, amount_);
            }
        } else {
            revert("SolvBTCRouter: stake amount exceeds sft balance");
        }
    }

    function unstake(address solvBTCAddress_, uint256 amount_, address sft_, uint256 slot_, uint256 sftId_)
        external
        virtual
        nonReentrant
        returns (uint256 toSftId_)
    {
        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotWithdrawAllowed(sft_, slot_),
            "SolvBTCRouter: sft slot not allowed"
        );
        require(
            solvBTCAddress_ == ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getERC20(sft_, slot_),
            "SolvBTCRouter: solvBTC address not matched"
        );
        require(amount_ > 0, "SolvBTCRouter: unstake amount cannot be 0");
        ERC20TransferHelper.doTransferIn(solvBTCAddress_, msg.sender, amount_);

        if (holdingSftIds[sft_][slot_] == 0) {
            holdingSftIds[sft_][slot_] = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).withdraw(sft_, slot_, 0, amount_);
        } else {
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).withdraw(sft_, slot_, holdingSftIds[sft_][slot_], amount_);
        }

        if (sftId_ == 0) {
            toSftId_ = ERC3525TransferHelper.doTransferOut(sft_, holdingSftIds[sft_][slot_], msg.sender, amount_);
        } else {
            require(slot_ == IERC3525(sft_).slotOf(sftId_), "SolvBTCRouter: sftId slot not matched");
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCRouter: not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, holdingSftIds[sft_][slot_], sftId_, amount_);
            toSftId_ = sftId_;
        }

        emit Unstake(solvBTCAddress_, msg.sender, sft_, slot_, toSftId_, amount_);
    }

    function createSubscription(bytes32 poolId_, uint256 currencyAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 shareValue_)
    {
        require(checkPoolPermission(poolId_), "SolvBTCRouter: pool permission denied");
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        ERC20TransferHelper.doTransferIn(poolInfo.currency, msg.sender, currencyAmount_);
        ERC20TransferHelper.doApprove(poolInfo.currency, openFundMarket, currencyAmount_);
        shareValue_ =
            IOpenFundMarket(openFundMarket).subscribe(poolId_, currencyAmount_, 0, uint64(block.timestamp + 300));

        uint256 shareCount = openFundShare.balanceOf(address(this));
        uint256 shareId = openFundShare.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(openFundShare.slotOf(shareId) == openFundShareSlot, "SolvBTCRouter: incorrect share slot");
        require(openFundShare.balanceOf(shareId) == shareValue_, "SolvBTCRouter: incorrect share value");

        openFundShare.approve(solvBTCMultiAssetPool, shareId);
        ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(openFundShare), shareId, shareValue_);

        address solvBTC =
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getERC20(address(openFundShare), openFundShareSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(msg.sender), shareValue_);

        emit CreateSubscription(poolId_, msg.sender, solvBTC, shareValue_, poolInfo.currency, currencyAmount_);
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

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotWithdrawAllowed(
                address(openFundShare), openFundShareSlot
            ),
            "SolvBTCRouter: sft slot not allowed"
        );

        address solvBTC =
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getERC20(address(openFundShare), openFundShareSlot);
        ERC20TransferHelper.doTransferIn(solvBTC, msg.sender, redeemAmount_);
        uint256 shareId = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).withdraw(
            address(openFundShare), openFundShareSlot, 0, redeemAmount_
        );

        ERC3525TransferHelper.doApproveId(address(openFundShare), openFundMarket, shareId);
        IOpenFundMarket(openFundMarket).requestRedeem(poolId_, shareId, 0, redeemAmount_);

        uint256 redemptionBalance = openFundRedemption.balanceOf(address(this));
        redemptionId_ = openFundRedemption.tokenOfOwnerByIndex(address(this), redemptionBalance - 1);
        require(
            openFundRedemption.balanceOf(redemptionId_) == redeemAmount_, "SolvBTCRouter: incorrect redemption value"
        );
        ERC3525TransferHelper.doTransferOut(address(openFundRedemption), payable(msg.sender), redemptionId_);

        emit CreateRedemption(poolId_, msg.sender, solvBTC, redeemAmount_, redemptionId_);
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

        openFundShare.approve(solvBTCMultiAssetPool, shareId);
        ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(openFundShare), shareId, shareValue);
        address solvBTC =
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getERC20(address(openFundShare), openFundShareSlot);

        ERC20TransferHelper.doTransferOut(solvBTC, payable(msg.sender), shareValue);

        emit CancelRedemption(poolId_, msg.sender, solvBTC, openFundRedemptionId_, shareValue);
    }

    function checkPoolPermission(bytes32 poolId_) public view virtual returns (bool) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        if (poolInfo.permissionless) {
            return true;
        }
        address whiteListManager = IOpenFundMarket(openFundMarket).getAddress("OFMWhitelistStrategyManager");
        return IOFMWhitelistStrategyManager(whiteListManager).isWhitelisted(poolId_, msg.sender);
    }

    function setOpenFundMarket(address openFundMarket_) external virtual onlyAdmin {
        _setOpenFundMarket(openFundMarket_);
    }

    function _setOpenFundMarket(address openFundMarket_) internal virtual {
        require(openFundMarket_ != address(0), "SolvBTCRouter: invalid openFundMarket");
        emit SetOpenFundMarket(openFundMarket, openFundMarket_);
        openFundMarket = openFundMarket_;
    }

    function setSolvBTCMultiAssetPool(address solvBTCMultiAssetPool_) external virtual onlyAdmin {
        _setSolvBTCMultiAssetPool(solvBTCMultiAssetPool_);
    }

    function _setSolvBTCMultiAssetPool(address solvBTCMultiAssetPool_) internal virtual {
        require(solvBTCMultiAssetPool_ != address(0), "SolvBTCRouter: invalid solvBTCMultiAssetPool");
        emit SetSolvBTCMultiAssetPool(solvBTCMultiAssetPool, solvBTCMultiAssetPool_);
        solvBTCMultiAssetPool = solvBTCMultiAssetPool_;
    }

    uint256[47] private __gap;
}
