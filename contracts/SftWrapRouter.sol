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
import "../lib/forge-std/src/console.sol";

contract SftWrapRouter is ISftWrapRouter, ReentrancyGuardUpgradeable, AdminControlUpgradeable, GovernorControlUpgradeable {

    event CreateSubscription(bytes32 indexed poolId, address indexed subscriber, address sftWrappedToken, uint256 swtTokenAmount, address currency, uint256 currencyAmount);
    event CreateRedemption(bytes32 indexed poolId, address indexed redeemer, address indexed sftWrappedToken, uint256 redeemAmount, uint256 redemptionId);
    event CancelRedemption(bytes32 indexed poolId, address indexed owner, address indexed sftWrappedToken, uint256 redemptionId, uint256 cancelAmount);
    event Stake(address indexed sftWrappedToken, address indexed staker, address sft, uint256 sftSlot, uint256 sftId, uint256 amount);
    event Unstake(address indexed sftWrappedToken, address indexed unstaker, address sft, uint256 sftSlot, uint256 sftId, uint256 amount);

    address public openFundMarket;
    address public sftWrappedTokenFactory;

    // sft address => sft slot => holding sft id
    mapping(address => mapping(uint256 => uint256)) public holdingSftIds;

    function initialize(address governor_, address openFundMarket_, address sftWrappedTokenFactory_) external initializer {
        AdminControlUpgradeable.__AdminControl_init(msg.sender);
        GovernorControlUpgradeable.__GovernorControl_init(governor_);
        openFundMarket = openFundMarket_;
        sftWrappedTokenFactory = sftWrappedTokenFactory_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC3525Receiver).interfaceId || 
            interfaceId == type(IERC721Receiver).interfaceId || 
            interfaceId == type(IERC165).interfaceId;
    }

    function onERC3525Received(address /* operator_ */, uint256 fromSftId_, uint256 toSftId_, uint256 value_, bytes calldata /* data_ */) 
        external 
        virtual 
        override 
        returns (bytes4) 
    {
        IERC3525 openFundShare = IERC3525(msg.sender);
        uint256 openFundShareSlot = openFundShare.slotOf(toSftId_);
        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(address(openFundShare), openFundShareSlot);
        require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");

        address fromSftIdOwner = openFundShare.ownerOf(fromSftId_);
        if (fromSftIdOwner == openFundMarket || fromSftIdOwner == sftWrappedToken) {
            return IERC3525Receiver.onERC3525Received.selector;
        }

        address toSftIdOwner = openFundShare.ownerOf(toSftId_);
        require(toSftIdOwner == address(this), "SftWrapRouter: not owned sft id");

        if (holdingSftIds[address(openFundShare)][openFundShareSlot] == 0) {
            holdingSftIds[address(openFundShare)][openFundShareSlot] = toSftId_;
        } else {
            require(toSftId_ == holdingSftIds[address(openFundShare)][openFundShareSlot], "SftWrapRouter: not holding sft id");
        }

        {
            uint256 swtHoldingValueSftId = SftWrappedToken(sftWrappedToken).holdingValueSftId();
            if (swtHoldingValueSftId == 0) {
                ERC3525TransferHelper.doTransferOut(address(openFundShare), toSftId_, sftWrappedToken, value_);
            } else {
                ERC3525TransferHelper.doTransfer(address(openFundShare), toSftId_, swtHoldingValueSftId, value_);
            }
        }

        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(fromSftIdOwner), value_);
        emit Stake(sftWrappedToken, fromSftIdOwner, address(openFundShare), openFundShareSlot, fromSftId_, value_);
        return IERC3525Receiver.onERC3525Received.selector;
    }

    function onERC721Received(address /* operator_ */, address from_, uint256 sftId_, bytes calldata /* data_ */) 
        external 
        virtual 
        override 
        returns (bytes4) 
    {
        IERC3525 openFundShare = IERC3525(msg.sender);
        uint256 openFundShareSlot = openFundShare.slotOf(sftId_);
        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(address(openFundShare), openFundShareSlot);
        require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");

        if (from_ == sftWrappedToken || from_ == openFundMarket) {
            return IERC721Receiver.onERC721Received.selector;
        }

        address sftIdOwner = openFundShare.ownerOf(sftId_);
        require(sftIdOwner == address(this), "SftWrapRouter: not owned sft id");

        uint256 openFundShareValue = openFundShare.balanceOf(sftId_);
        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), sftWrappedToken, sftId_);
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

    function unstake(address swtAddress_, uint256 amount_, uint256 sftId_) external virtual nonReentrant returns (uint256 toSftId_) {
        require(amount_ > 0, "SftWrapRouter: unstake amount cannot be 0");
        ERC20TransferHelper.doTransferIn(swtAddress_, msg.sender, amount_);

        SftWrappedToken swt = SftWrappedToken(swtAddress_);
        address sftAddress = swt.wrappedSftAddress();
        uint256 slot = swt.wrappedSftSlot();

        if (holdingSftIds[sftAddress][slot] == 0) {
            holdingSftIds[sftAddress][slot] = swt.burn(amount_, 0);
        } else {
            swt.burn(amount_, holdingSftIds[sftAddress][slot]);
        }

        if (sftId_ == 0) {
            toSftId_ = ERC3525TransferHelper.doTransferOut(sftAddress, holdingSftIds[sftAddress][slot], msg.sender, amount_);
        } else {
            require(slot == IERC3525(sftAddress).slotOf(sftId_), "SftWrapRouter: slot does not match");
            require(msg.sender == IERC3525(sftAddress).ownerOf(sftId_), "SftWrapRouter: not sft owner");
            ERC3525TransferHelper.doTransfer(sftAddress, holdingSftIds[sftAddress][slot], sftId_, amount_);
            toSftId_ = sftId_;
        }

        emit Unstake(swtAddress_, msg.sender, sftAddress, slot, toSftId_, amount_);
    }

    function createSubscription(bytes32 poolId_, uint256 currencyAmount_) external payable virtual nonReentrant returns (uint256 shareValue_) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;
        ERC20TransferHelper.doTransferIn(poolInfo.currency, msg.sender, currencyAmount_);

        ERC20TransferHelper.doApprove(poolInfo.currency, openFundMarket, currencyAmount_);
        shareValue_ = IOpenFundMarket(openFundMarket).subscribe(poolId_, currencyAmount_, 0, uint64(block.timestamp + 300));

        uint256 shareCount = openFundShare.balanceOf(address(this));
        uint256 shareId = openFundShare.tokenOfOwnerByIndex(address(this), shareCount - 1);
        require(openFundShare.slotOf(shareId) == openFundShareSlot, "SftWrapRouter: incorrect share slot");
        require(openFundShare.balanceOf(shareId) == shareValue_, "SftWrapRouter: incorrect share value");

        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(address(openFundShare), openFundShareSlot);
        require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");

        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), sftWrappedToken, shareId);
        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(msg.sender), shareValue_);

        emit CreateSubscription(poolId_, msg.sender, sftWrappedToken, shareValue_, poolInfo.currency, currencyAmount_);
    }

    function createRedemption(bytes32 poolId_, uint256 redeemAmount_) external virtual nonReentrant returns (uint256 redemptionId_) {
        PoolInfo memory poolInfo = IOpenFundMarket(openFundMarket).poolInfos(poolId_);
        IERC3525 openFundShare = IERC3525(poolInfo.poolSFTInfo.openFundShare);
        IERC3525 openFundRedemption = IERC3525(poolInfo.poolSFTInfo.openFundRedemption);
        uint256 openFundShareSlot = poolInfo.poolSFTInfo.openFundShareSlot;

        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(address(openFundShare), openFundShareSlot);
        require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");
        ERC20TransferHelper.doTransferIn(sftWrappedToken, msg.sender, redeemAmount_);

        uint256 shareId = ISftWrappedToken(sftWrappedToken).burn(redeemAmount_, 0);
        ERC3525TransferHelper.doApproveId(address(openFundShare), openFundMarket, shareId);
        IOpenFundMarket(openFundMarket).requestRedeem(poolId_, shareId, 0, redeemAmount_);

        uint256 redemptionBalance = openFundRedemption.balanceOf(address(this));
        redemptionId_ = openFundRedemption.tokenOfOwnerByIndex(address(this), redemptionBalance - 1);
        require(openFundRedemption.balanceOf(redemptionId_) == redeemAmount_, "SftWrapRouter: incorrect redemption value");
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

        address sftWrappedToken = SftWrappedTokenFactory(sftWrappedTokenFactory).sftWrappedTokens(address(openFundShare), openFundShareSlot);
        require(sftWrappedToken != address(0), "SftWrapRouter: sft wrapped token not created");

        ERC3525TransferHelper.doSafeTransferOut(address(openFundShare), sftWrappedToken, shareId);
        ERC20TransferHelper.doTransferOut(sftWrappedToken, payable(msg.sender), shareValue);

        emit CancelRedemption(poolId_, msg.sender, sftWrappedToken, openFundRedemptionId_, shareValue);
    }

}