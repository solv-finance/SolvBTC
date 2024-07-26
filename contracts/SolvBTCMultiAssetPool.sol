// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./access/AdminControlUpgradeable.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./ISolvBTCMultiAssetPool.sol";
import "./ISolvBTC.sol";

contract SolvBTCMultiAssetPool is ISolvBTCMultiAssetPool, ReentrancyGuardUpgradeable, AdminControlUpgradeable {
    struct SftSlotInfo {
        uint256 holdingValueSftId;
        address erc20;
        bool depositAllowed;
        bool withdrawAllowed;
    }

    mapping(address => mapping(uint256 => SftSlotInfo)) internal _sftSlotInfos;

    event AddSftSlot(address indexed sft, uint256 indexed slot, address indexed erc20, uint256 holdingValueSftId);
    event SftSlotAllowedChanged(address indexed sft, uint256 indexed slot, bool depositAllowed, bool withdrawAllowed);
    event Deposit(
        address indexed owner, address indexed sft, uint256 indexed slot, address erc20, uint256 sftId, uint256 value
    );
    event Withdraw(
        address indexed owner, address indexed sft, uint256 indexed slot, address erc20, uint256 sftId, uint256 value
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_) external virtual initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AdminControlUpgradeable.__AdminControl_init(admin_);
    }

    function deposit(address sft_, uint256 sftId_, uint256 value_) external virtual override nonReentrant {
        require(value_ > 0, "SolvBTCMultiAssetPool: deposit amount cannot be 0");
        require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMultiAssetPool: caller is not sft owner");

        uint256 slot = IERC3525(sft_).slotOf(sftId_);
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot];
        require(sftSlotInfo.depositAllowed, "SolvBTCMultiAssetPool: sft slot deposit not allowed");

        uint256 sftBalance = IERC3525(sft_).balanceOf(sftId_);
        if (value_ == sftBalance) {
            ERC3525TransferHelper.doTransferIn(sft_, msg.sender, sftId_);
            if (sftSlotInfo.holdingValueSftId == 0) {
                sftSlotInfo.holdingValueSftId = sftId_;
            } else {
                ERC3525TransferHelper.doTransfer(sft_, sftId_, sftSlotInfo.holdingValueSftId, value_);
                ERC3525TransferHelper.doTransferOut(sft_, 0x000000000000000000000000000000000000dEaD, sftId_);
            }
        } else if (value_ < sftBalance) {
            if (sftSlotInfo.holdingValueSftId == 0) {
                sftSlotInfo.holdingValueSftId = ERC3525TransferHelper.doTransferIn(sft_, sftId_, value_);
            } else {
                ERC3525TransferHelper.doTransfer(sft_, sftId_, sftSlotInfo.holdingValueSftId, value_);
            }
        } else {
            revert("SolvBTCMultiAssetPool: deposit amount exceeds sft balance");
        }

        ISolvBTC(sftSlotInfo.erc20).mint(msg.sender, value_);
        emit Deposit(msg.sender, sft_, slot, sftSlotInfo.erc20, sftId_, value_);
    }

    function withdraw(address sft_, uint256 slot_, uint256 sftId_, uint256 value_)
        external
        virtual
        override
        nonReentrant
        returns (uint256 toSftId_)
    {
        require(value_ > 0, "SolvBTCMultiAssetPool: withdraw amount cannot be 0");

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.withdrawAllowed, "SolvBTCMultiAssetPool: sft slot not allowed");

        uint256 sftSlotBalance = getSftSlotBalance(sft_, slot_);
        require(value_ <= sftSlotBalance, "SolvBTCMultiAssetPool: insufficient balance");

        ISolvBTC(sftSlotInfo.erc20).burn(msg.sender, value_);

        if (sftId_ == 0) {
            toSftId_ = ERC3525TransferHelper.doTransferOut(sft_, sftSlotInfo.holdingValueSftId, msg.sender, value_);
        } else {
            require(slot_ == IERC3525(sft_).slotOf(sftId_), "SolvBTCMultiAssetPool: slot not matched");
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMultiAssetPool: caller is not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, sftSlotInfo.holdingValueSftId, sftId_, value_);
            toSftId_ = sftId_;
        }

        emit Withdraw(msg.sender, sft_, slot_, sftSlotInfo.erc20, toSftId_, value_);
    }

    function addSftSlotOnlyAdmin(address sft_, uint256 slot_, address erc20_, uint256 holdingValueSftId_)
        external
        virtual
        onlyAdmin
    {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.erc20 == address(0), "SolvBTCMultiAssetPool: sft slot already existed");
        require(
            IERC3525(sft_).valueDecimals() == IERC20Metadata(erc20_).decimals(),
            "SolvBTCMultiAssetPool: decimals not matched"
        );
        if (holdingValueSftId_ > 0) {
            require(IERC3525(sft_).slotOf(holdingValueSftId_) == slot_, "SolvBTCMultiAssetPool: slot not matched");
            require(
                IERC3525(sft_).ownerOf(holdingValueSftId_) == address(this), "SolvBTCMultiAssetPool: sftId not owned"
            );
        }

        sftSlotInfo.holdingValueSftId = holdingValueSftId_;
        sftSlotInfo.erc20 = erc20_;
        sftSlotInfo.depositAllowed = true;
        sftSlotInfo.withdrawAllowed = true;
        emit AddSftSlot(sft_, slot_, erc20_, holdingValueSftId_);
    }

    function changeSftSlotAllowedOnlyAdmin(address sft_, uint256 slot_, bool depositAllowed_, bool withdrawAllowed_)
        external
        virtual
        onlyAdmin
    {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.erc20 != address(0), "SolvBTCMultiAssetPool: sft slot not existed");

        sftSlotInfo.depositAllowed = depositAllowed_;
        sftSlotInfo.withdrawAllowed = withdrawAllowed_;
        emit SftSlotAllowedChanged(sft_, slot_, depositAllowed_, withdrawAllowed_);
    }

    function isSftSlotDepositAllowed(address sft_, uint256 slot_) public view virtual override returns (bool) {
        return _sftSlotInfos[sft_][slot_].depositAllowed;
    }

    function isSftSlotWithdrawAllowed(address sft_, uint256 slot_) public view virtual override returns (bool) {
        return _sftSlotInfos[sft_][slot_].withdrawAllowed;
    }

    function getERC20(address sft_, uint256 slot_) public view virtual override returns (address) {
        return _sftSlotInfos[sft_][slot_].erc20;
    }

    function getHoldingValueSftId(address sft_, uint256 slot_) public view virtual override returns (uint256) {
        return _sftSlotInfos[sft_][slot_].holdingValueSftId;
    }

    function getSftSlotBalance(address sft_, uint256 slot_) public view virtual override returns (uint256) {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        return sftSlotInfo.holdingValueSftId == 0 ? 0 : IERC3525(sft_).balanceOf(sftSlotInfo.holdingValueSftId);
    }

    uint256[49] private __gap;
}
