// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        uint256[] holdingEmptySftIds;
        address solvBTC;
        bool allowed;
    }

    mapping(address => mapping(uint256 => SftSlotInfo)) internal _sftSlotInfos;

    event AddSftSlot(address indexed sft, uint256 indexed slot, address indexed solvBTC, uint256 holdingValueSftId);
    event RemoveSftSlot(address indexed sft, uint256 indexed slot, address indexed solvBTC);
    event Deposit(address indexed owner, address indexed sft, uint256 indexed slot, address solvBTC, uint256 sftId, uint256 value);
    event Withdraw(address indexed owner, address indexed sft, uint256 indexed slot, address solvBTC, uint256 sftId, uint256 value);

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
        require(sftSlotInfo.allowed, "SolvBTCMultiAssetPool: sft slot not allowed");

        uint256 sftBalance = IERC3525(sft_).balanceOf(sftId_);
        if (value_ == sftBalance) {
            ERC3525TransferHelper.doTransferIn(sft_, msg.sender, sftId_);
            if (sftSlotInfo.holdingValueSftId == 0) {
                sftSlotInfo.holdingValueSftId = sftId_;
            } else {
                ERC3525TransferHelper.doTransfer(sft_, sftId_, sftSlotInfo.holdingValueSftId, value_);
                sftSlotInfo.holdingEmptySftIds.push(sftId_);
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

        ISolvBTC(sftSlotInfo.solvBTC).mint(msg.sender, value_);
        emit Deposit(msg.sender, sft_, slot, sftSlotInfo.solvBTC, sftId_, value_);
    }

    function withdraw(
        address sft_, uint256 slot_, uint256 sftId_, uint256 value_
    ) 
        external virtual override nonReentrant returns (uint256 toSftId_) 
    {
        require(value_ > 0, "SolvBTCMultiAssetPool: withdraw amount cannot be 0");

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.allowed, "SolvBTCMultiAssetPool: sft slot not allowed");

        uint256 sftSlotBalance = getSftSlotBalance(sft_, slot_);
        require(value_ <= sftSlotBalance, "SolvBTCMultiAssetPool: insufficient balance");

        ISolvBTC(sftSlotInfo.solvBTC).burn(msg.sender, value_);

        if (sftId_ == 0) {
            if (sftSlotInfo.holdingEmptySftIds.length == 0) {
                toSftId_ = ERC3525TransferHelper.doTransferOut(
                    sft_, sftSlotInfo.holdingValueSftId, msg.sender, value_
                );
            } else {
                toSftId_ = sftSlotInfo.holdingEmptySftIds[sftSlotInfo.holdingEmptySftIds.length - 1];
                sftSlotInfo.holdingEmptySftIds.pop();
                ERC3525TransferHelper.doTransfer(sft_, sftSlotInfo.holdingValueSftId, toSftId_, value_);
                ERC3525TransferHelper.doTransferOut(sft_, msg.sender, toSftId_);
            }
        } else {
            require(slot_ == IERC3525(sft_).slotOf(sftId_), "SolvBTCMultiAssetPool: slot does not match");
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMultiAssetPool: caller is not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, sftSlotInfo.holdingValueSftId, sftId_, value_);
            toSftId_ = sftId_;
        }

        emit Withdraw(msg.sender, sft_, slot_, sftSlotInfo.solvBTC, toSftId_, value_);
    }

    function addSftSlotOnlyAdmin(
        address sft_, uint256 slot_, address solvBTC_, uint256 holdingValueSftId_
    ) 
        external virtual onlyAdmin 
    {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(!sftSlotInfo.allowed, "SolvBTCMultiAssetPool: sft slot already existed");
        require(
            IERC3525(sft_).valueDecimals() == IERC20Metadata(solvBTC_).decimals(), 
            "SolvBTCMultiAssetPool: decimals do not match"
        );
        if (holdingValueSftId_ > 0) {
            require(IERC3525(sft_).slotOf(holdingValueSftId_) == slot_, "SolvBTCMultiAssetPool: slot does not match");
            require(IERC3525(sft_).ownerOf(holdingValueSftId_) == address(this), "SolvBTCMultiAssetPool: sftId not owned");
        }

        sftSlotInfo.holdingValueSftId = holdingValueSftId_;
        sftSlotInfo.solvBTC = solvBTC_;
        sftSlotInfo.allowed = true;
        emit AddSftSlot(sft_, slot_, solvBTC_, holdingValueSftId_);
    } 

    function removeSftSlotOnlyAdmin(
        address sft_, uint256 slot_, address solvBTC_
    ) 
        external virtual onlyAdmin 
    {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.allowed, "SolvBTCMultiAssetPool: sft slot not allowed");

        if (sftSlotInfo.holdingValueSftId > 0) {
            uint256 sftIdBalance = IERC3525(sft_).balanceOf(sftSlotInfo.holdingValueSftId);
            require(sftIdBalance == 0, "SolvBTCMultiAssetPool: holdingValueSftId balance not empty");
        }

        sftSlotInfo.holdingValueSftId = 0;
        sftSlotInfo.solvBTC = address(0);
        sftSlotInfo.allowed = false;
        emit RemoveSftSlot(sft_, slot_, solvBTC_);
    }

    function sweepEmptySftIdsOnlyAdmin(
        address sft_, uint256 slot_, address recipient_, uint256 sweepAmount_
    ) 
        external virtual onlyAdmin 
    {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(!sftSlotInfo.allowed, "SolvBTCMultiAssetPool: sft slot not removed");

        uint256 length = sftSlotInfo.holdingEmptySftIds.length;
        for (uint256 i = 0; i < sweepAmount_ && i < length; i++) {
            uint256 lastSftId = sftSlotInfo.holdingEmptySftIds[sftSlotInfo.holdingEmptySftIds.length - 1];
            ERC3525TransferHelper.doTransferOut(sft_, recipient_, lastSftId);
            sftSlotInfo.holdingEmptySftIds.pop();
        }
        if (sftSlotInfo.holdingEmptySftIds.length == 0) {
            delete sftSlotInfo.holdingEmptySftIds;
        }
    }

    function isSftSlotAllowed(address sft_, uint256 slot_) public view virtual override returns (bool) {
        return _sftSlotInfos[sft_][slot_].allowed;
    }

    function getSolvBTC(address sft_, uint256 slot_) public view virtual override returns (address) {
        return _sftSlotInfos[sft_][slot_].solvBTC;
    }

    function getHoldingValueSftId(address sft_, uint256 slot_) public view virtual override returns (uint256) {
        return _sftSlotInfos[sft_][slot_].holdingValueSftId;
    }

    function getSftSlotBalance(address sft_, uint256 slot_) public view virtual override returns (uint256) {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        return sftSlotInfo.holdingValueSftId == 0 ? 0 : 
            IERC3525(sft_).balanceOf(sftSlotInfo.holdingValueSftId);
    }

    uint256[48] private __gap;
}
