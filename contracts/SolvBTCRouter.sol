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

    // sft address => sft slot => holding sft id
    mapping(address => mapping(uint256 => uint256)) public holdingSftIds;

    address public solvBTCMultiAssetPool;

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
        openFundMarket = openFundMarket_;
        solvBTCMultiAssetPool = solvBTCMultiAssetPool_;
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
        IERC3525 solvBTCSft = IERC3525(msg.sender);
        uint256 solvBTCSlot = solvBTCSft.slotOf(toSftId_);

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotAllowed(msg.sender, solvBTCSlot), 
            "SolvBTCRouter: sft slot not allowed"
        );
        require(value_ > 0, "SolvBTCRouter: stake amount cannot be 0");

        address fromSftIdOwner = solvBTCSft.ownerOf(fromSftId_);
        if (fromSftIdOwner == openFundMarket || fromSftIdOwner == solvBTCMultiAssetPool) {
            return IERC3525Receiver.onERC3525Received.selector;
        }

        address toSftIdOwner = solvBTCSft.ownerOf(toSftId_);
        require(toSftIdOwner == address(this), "SolvBTCRouter: not owned sft id");

        if (holdingSftIds[address(solvBTCSft)][solvBTCSlot] == 0) {
            holdingSftIds[address(solvBTCSft)][solvBTCSlot] = toSftId_;
        } else {
            require(
                toSftId_ == holdingSftIds[address(solvBTCSft)][solvBTCSlot],
                "SolvBTCRouter: not holding sft id"
            );
        }
        {
            uint256 newSftId = IERC3525(msg.sender).transferFrom(toSftId_, address(this), value_);
            solvBTCSft.approve(solvBTCMultiAssetPool, newSftId);
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(solvBTCSft), newSftId, value_);
        }
        address solvBTC = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getSolvBTC(address(solvBTCSft), solvBTCSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(fromSftIdOwner), value_);

        emit Stake(solvBTC, fromSftIdOwner, address(solvBTCSft), solvBTCSlot, fromSftId_, value_);
        return IERC3525Receiver.onERC3525Received.selector;
    }

    function onERC721Received(address, /* operator_ */ address from_, uint256 sftId_, bytes calldata /* data_ */ )
        external
        virtual
        override
        returns (bytes4)
    {
        IERC3525 solvBTCSft = IERC3525(msg.sender);
        uint256 solvBTCSlot = solvBTCSft.slotOf(sftId_);

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotAllowed(msg.sender, solvBTCSlot), 
            "SolvBTCRouter: sft slot not allowed"
        );

        if (from_ == openFundMarket || from_ == solvBTCMultiAssetPool) {
            return IERC721Receiver.onERC721Received.selector;
        }

        uint256 value = solvBTCSft.balanceOf(sftId_);
        require(value > 0, "SolvBTCRouter: stake amount cannot be 0");

        address sftIdOwner = solvBTCSft.ownerOf(sftId_);
        require(sftIdOwner == address(this), "SolvBTCRouter: not owned sft id");

        solvBTCSft.approve(solvBTCMultiAssetPool, sftId_);
        ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(solvBTCSft), sftId_, value);

        address solvBTC = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getSolvBTC(address(solvBTCSft), solvBTCSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(from_), value);

        emit Stake(solvBTC, from_, address(solvBTCSft), solvBTCSlot, sftId_, value);
        return IERC721Receiver.onERC721Received.selector;
    }

    function stake(address sft_, uint256 sftId_, uint256 value_) external virtual nonReentrant {
        uint256 solvBTCSlot = IERC3525(sft_).slotOf(sftId_);
        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotAllowed(msg.sender, solvBTCSlot), 
            "SolvBTCRouter: sft slot not allowed"
        );

        require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCRouter: caller is not sft owner");
        require(value_ > 0, "SolvBTCRouter: stake amount cannot be 0");

        uint256 sftBalance = IERC3525(sft_).balanceOf(sftId_);
        if (value_ == sftBalance) {
            ERC3525TransferHelper.doSafeTransferIn(sft_, msg.sender, sftId_);
        } else if (value_ < sftBalance) {
            uint256 holdingSftId = holdingSftIds[sft_][solvBTCSlot];
            if (holdingSftId == 0) {
                ERC3525TransferHelper.doTransferIn(sft_, sftId_, value_);
            } else {
                ERC3525TransferHelper.doTransfer(sft_, sftId_, holdingSftId, value_);
            }
        } else {
            revert("SolvBTCRouter: stake amount exceeds sft balance");
        }
    }

    function unstake(address solvBTC_, uint256 value_, address sft_, uint256 slot_, uint256 sftId_)
        external
        virtual
        nonReentrant
        returns (uint256 toSftId_)
    {
        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotAllowed(sft_, slot_), 
            "SolvBTCRouter: sft slot not allowed"
        );
        require(
            solvBTC_ == ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getSolvBTC(sft_, slot_),
            "SolvBTCRouter: solvBTC and sft slot not matched"
        );
        require(value_ > 0, "SolvBTCRouter: unstake amount cannot be 0");

        ERC20TransferHelper.doTransferIn(solvBTC_, msg.sender, value_);
        if (holdingSftIds[sft_][slot_] == 0) {
            holdingSftIds[sft_][slot_] = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).withdraw(sft_, slot_, 0, value_);
        } else {
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).withdraw(sft_, slot_, holdingSftIds[sft_][slot_], value_);
        }

        if (sftId_ == 0) {
            toSftId_ = ERC3525TransferHelper.doTransferOut(sft_, holdingSftIds[sft_][slot_], msg.sender, value_);
        } else {
            require(slot_ == IERC3525(sft_).slotOf(sftId_), "SolvBTCRouter: sftId slot not matched");
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCRouter: not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, holdingSftIds[sft_][slot_], sftId_, value_);
            toSftId_ = sftId_;
        }

        emit Unstake(solvBTC_, msg.sender, sft_, slot_, toSftId_, value_);
    }

    function createSubscription(bytes32 poolId_, uint256 currencyAmount_)
        external
        virtual
        nonReentrant
        returns (uint256 value_)
    {
        require(checkPoolPermission(poolId_), "SolvBTCRouter: pool permission denied");
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 solvBTCSft = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 solvBTCSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        ERC20TransferHelper.doTransferIn(poolInfo.currency, msg.sender, currencyAmount_);
        ERC20TransferHelper.doApprove(poolInfo.currency, openFundMarket, currencyAmount_);
        value_ = IOpenFundMarket(openFundMarket).subscribe(
            poolId_, currencyAmount_, 0, uint64(block.timestamp + 300)
        );

        uint256 sftCount = solvBTCSft.balanceOf(address(this));
        uint256 sftId = solvBTCSft.tokenOfOwnerByIndex(address(this), sftCount - 1);
        require(solvBTCSft.slotOf(sftId) == solvBTCSlot, "SolvBTCRouter: incorrect sft slot");
        require(solvBTCSft.balanceOf(sftId) == value_, "SolvBTCRouter: incorrect sft value");

        solvBTCSft.approve(solvBTCMultiAssetPool, sftId);
        ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(solvBTCSft), sftId, value_);

        address solvBTC = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getSolvBTC(address(solvBTCSft), solvBTCSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(msg.sender), value_);

        emit CreateSubscription(poolId_, msg.sender, solvBTC, value_, poolInfo.currency, currencyAmount_);
    }

    function createRedemption(bytes32 poolId_, uint256 redeemValue_)
        external
        virtual
        nonReentrant
        returns (uint256 redemptionSftId_)
    {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 solvBTCSft = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        IERC3525 redemptionSft = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
        uint256 solvBTCSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        require(
            ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).isSftSlotAllowed(address(solvBTCSft), solvBTCSlot), 
            "SolvBTCRouter: sft slot not allowed"
        );

        address solvBTC = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getSolvBTC(address(solvBTCSft), solvBTCSlot);
        ERC20TransferHelper.doTransferIn(solvBTC, msg.sender, redeemValue_);
        uint256 sftId = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).withdraw(address(solvBTCSft), solvBTCSlot, 0, redeemValue_);

        ERC3525TransferHelper.doApproveId(address(solvBTCSft), openFundMarket, sftId);
        IOpenFundMarket(openFundMarket).requestRedeem(poolId_, sftId, 0, redeemValue_);

        uint256 redemptionBalance = redemptionSft.balanceOf(address(this));
        redemptionSftId_ = redemptionSft.tokenOfOwnerByIndex(address(this), redemptionBalance - 1);
        require(
            redemptionSft.balanceOf(redemptionSftId_) == redeemValue_, "SolvBTCRouter: incorrect redemption value"
        );
        ERC3525TransferHelper.doTransferOut(address(redemptionSft), payable(msg.sender), redemptionSftId_);

        emit CreateRedemption(poolId_, msg.sender, solvBTC, redeemValue_, redemptionSftId_);
    }

    function cancelRedemption(bytes32 poolId_, uint256 redemptionSftId_) external virtual nonReentrant {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 solvBTCSft = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        IERC3525 redemptionSft = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
        uint256 solvBTCSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        ERC3525TransferHelper.doTransferIn(address(redemptionSft), msg.sender, redemptionSftId_);
        ERC3525TransferHelper.doApproveId(address(redemptionSft), openFundMarket, redemptionSftId_);
        IOpenFundMarket(openFundMarket).revokeRedeem(poolId_, redemptionSftId_);
        uint256 sftBalance = solvBTCSft.balanceOf(address(this));
        uint256 sftId = solvBTCSft.tokenOfOwnerByIndex(address(this), sftBalance - 1);
        uint256 sftValue = solvBTCSft.balanceOf(sftId);

        solvBTCSft.approve(solvBTCMultiAssetPool, sftId);
        ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).deposit(address(solvBTCSft), sftId, sftValue);

        address solvBTC = ISolvBTCMultiAssetPool(solvBTCMultiAssetPool).getSolvBTC(address(solvBTCSft), solvBTCSlot);
        ERC20TransferHelper.doTransferOut(solvBTC, payable(msg.sender), sftValue);

        emit CancelRedemption(poolId_, msg.sender, solvBTC, redemptionSftId_, sftValue);
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
