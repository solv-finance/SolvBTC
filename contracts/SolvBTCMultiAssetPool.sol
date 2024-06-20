// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./ISolvBTCMultiAssetPool.sol";
import "./ISolvBTC.sol";

contract SolvBTCMultiAssetPool is ISolvBTCMultiAssetPool, ReentrancyGuardUpgradeable, AdminControlUpgradeable {

    struct SftSlotInfo {
        uint256 holdingValueSftId;
        uint256[] holdingEmptySftIds;
        bool allowed;
    }

    mapping(address => mapping(uint256 => SftSlotInfo)) internal _sftSlotInfos;

    address public solvBTC;

    event SetSolvBTC(address indexed solvBTC);
    event AddSftSlot(address indexed sft, uint256 indexed slot, uint256 holdingValueSftId);
    event RemoveSftSlot(address indexed sft, uint256 indexed slot);
    event MintSolvBTC(address indexed owner, address sft, uint256 sftId, uint256 slot, uint256 value);
    event BurnSolvBTC(address indexed owner, address sft, uint256 sftId, uint256 slot, uint256 value);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin_) external virtual initializer {
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        AdminControlUpgradeable.__AdminControl_init(admin_);
    }

    function deposit(address sft_, uint256 sftId_, uint256 value_) external virtual override nonReentrant {
        require(solvBTC != address(0), "SolvBTCMultiAssetPool: SolvBTC not set");
        require(value_ > 0, "SolvBTCMultiAssetPool: mint amount cannot be 0");

        uint256 slot = IERC3525(sft_).slotOf(sftId_);
        require(isSftSlotAllowed(sft_, slot), "SolvBTCMultiAssetPool: sft and slot not allowed");
        require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMultiAssetPool: caller is not sft owner");

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot];

        uint256 sftBalance = IERC3525(sft_).balanceOf(sftId_);
        if (value_ == sftBalance) {
            ERC3525TransferHelper.doSafeTransferIn(sft_, msg.sender, sftId_);
            if (sftSlotInfo.holdingValueSftId == 0) {
                sftSlotInfo.holdingValueSftId = sftId_;
            } else {
                ERC3525TransferHelper.doTransfer(msg.sender, sftId_, sftSlotInfo.holdingValueSftId, value_);
                sftSlotInfo.holdingEmptySftIds.push(sftId_);
            }
        } else if (value_ < sftBalance) {
            if (sftSlotInfo.holdingValueSftId == 0) {
                sftSlotInfo.holdingValueSftId = ERC3525TransferHelper.doTransferIn(sft_, sftId_, value_);
            } else {
                ERC3525TransferHelper.doTransfer(sft_, sftId_, sftSlotInfo.holdingValueSftId, value_);
            }
        } else {
            revert("SolvBTCMultiAssetPool: mint amount exceeds sft balance");
        }
        // if (sftSlotInfo.holdingValueSftId == 0) {
        //     sftSlotInfo.holdingValueSftId = ERC3525TransferHelper.doTransferIn(sft_, sftId_, value_);
        // } else {
        //     ERC3525TransferHelper.doTransfer(sft_, sftId_, sftSlotInfo.holdingValueSftId, value_);
        // }

        ISolvBTC(solvBTC).mint(msg.sender, value_);
        emit MintSolvBTC(msg.sender, sft_, sftId_, slot, value_);
    }

    function withdraw(
        address sft_, 
        uint256 slot_, 
        uint256 sftId_, 
        uint256 value_
    ) 
        external virtual override nonReentrant returns (uint256 toSftId_) 
    {
        require(solvBTC != address(0), "SolvBTCMultiAssetPool: SolvBTC not set");
        require(value_ > 0, "SolvBTCMultiAssetPool: burn amount cannot be 0");

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.allowed, "SolvBTCMultiAssetPool: sft slot not allowed");

        uint256 sftSlotBalance = sftSlotInfo.holdingValueSftId == 0 ? 0 : 
            IERC3525(sft_).balanceOf(sftSlotInfo.holdingValueSftId);
        require(value_ <= sftSlotBalance, "SolvBTCMultiAssetPool: insufficient balance");

        ISolvBTC(solvBTC).burn(msg.sender, value_);

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
            require(
                slot_ == IERC3525(sft_).slotOf(sftId_), "SolvBTCMultiAssetPool: slot does not match"
            );
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMultiAssetPool: caller is not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, sftSlotInfo.holdingValueSftId, sftId_, value_);
            toSftId_ = sftId_;
        }

        emit BurnSolvBTC(msg.sender, sft_, toSftId_, slot_, value_);
    }

    function setSolvBTCOnlyAdmin(address solvBTC_) external virtual onlyAdmin {
        require(solvBTC == address(0), "SolvBTCMultiAssetPool: SolvBTC already set");
        solvBTC = solvBTC_;
        emit SetSolvBTC(solvBTC);
    }

    function addSftSlotOnlyAdmin(address sft_, uint256 slot_, uint256 holdingValueSftId_) external virtual onlyAdmin {
        if (holdingValueSftId_ > 0) {
            require(IERC3525(sft_).slotOf(holdingValueSftId_) == slot_, "SolvBTCMultiAssetPool: slot does not match");
        }

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        sftSlotInfo.holdingValueSftId = holdingValueSftId_;
        sftSlotInfo.allowed = true;
        emit AddSftSlot(sft_, slot_, holdingValueSftId_);
    } 

    function removeSftSlotOnlyAdmin(address sft_, uint256 slot_) external virtual onlyAdmin {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.allowed, "SolvBTCMultiAssetPool: invalid sft and slot");
        if (sftSlotInfo.holdingValueSftId > 0) {
            // uint256 balance = IERC3525(sft_).balanceOf()
        }
    }

    function isSftSlotAllowed(address sft_, uint256 slot_) public view virtual override returns (bool) {
        return _sftSlotInfos[sft_][slot_].allowed;
    }

    function getSftSlotBalance(address sft_, uint256 slot_) public view virtual override returns (uint256) {
        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        return sftSlotInfo.holdingValueSftId == 0 ? 0 : 
            IERC3525(sft_).balanceOf(sftSlotInfo.holdingValueSftId);
    }
}
