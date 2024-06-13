// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./access/AdminControlUpgradeable.sol";
import "./utils/ERC3525TransferHelper.sol";
import "./external/IERC3525.sol";
import "./ISolvBTCMinter.sol";
import "./ISolvBTC.sol";

contract SolvBTCMinter is ISolvBTCMinter, ReentrancyGuardUpgradeable, AdminControlUpgradeable {

    struct SftSlotInfo {
        uint256 holdingValueSftId;
        uint256[] holdingEmptySftIds;
        address oracle;
        bool allowed;
    }

    mapping(address => mapping(uint256 => SftSlotInfo)) internal _sftSlotInfos;

    address public solvBTC;

    event SetSolvBTC(address indexed solvBTC);
    event SetSftSlot(address indexed sft, uint256 indexed slot, address oracle, uint256 holdingValueSftId, bool allowed);
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

    function mint(address sft_, uint256 sftId_, uint256 value_) external virtual override nonReentrant {
        require(solvBTC != address(0), "SolvBTCMinter: SolvBTC not set");
        require(value_ > 0, "SolvBTCMinter: mint amount cannot be 0");

        uint256 slot = IERC3525(sft_).slotOf(sftId_);
        require(isSftSlotAllowed(sft_, slot), "SolvBTCMinter: sft and slot not allowed");
        require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMinter: caller is not sft owner");

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
            revert("SolvBTCMinter: mint amount exceeds sft balance");
        }

        ISolvBTC(solvBTC).mint(msg.sender, value_);
        emit MintSolvBTC(msg.sender, sft_, sftId_, slot, value_);
    }

    function burn(
        address sft_, 
        uint256 sftId_, 
        uint256 slot_, 
        uint256 value_
    ) 
        external virtual override nonReentrant returns (uint256 toSftId_) 
    {
        require(solvBTC != address(0), "SolvBTCMinter: SolvBTC not set");
        require(value_ > 0, "SolvBTCMinter: burn amount cannot be 0");

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        require(sftSlotInfo.allowed, "SolvBTCMinter: sft slot not allowed");

        uint256 sftSlotBalance = sftSlotInfo.holdingValueSftId == 0 ? 0 : 
            IERC3525(sft_).balanceOf(sftSlotInfo.holdingValueSftId);
        require(value_ <= sftSlotBalance, "SolvBTCMinter: insufficient balance");

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
                slot_ == IERC3525(sft_).slotOf(sftId_), "SolvBTCMinter: slot does not match"
            );
            require(msg.sender == IERC3525(sft_).ownerOf(sftId_), "SolvBTCMinter: caller is not sft owner");
            ERC3525TransferHelper.doTransfer(sft_, sftSlotInfo.holdingValueSftId, sftId_, value_);
            toSftId_ = sftId_;
        }

        emit BurnSolvBTC(msg.sender, sft_, toSftId_, slot_, value_);
    }

    function setSolvBTCOnlyAdmin(address solvBTC_) external virtual onlyAdmin {
        require(solvBTC == address(0), "SolvBTCMinter: SolvBTC already set");
        solvBTC = solvBTC_;
        emit SetSolvBTC(solvBTC);
    }

    function setSftSlotOnlyAdmin(
        address sft_, 
        uint256 slot_, 
        address oracle_, 
        uint256 holdingValueSftId_,
        bool allowed_
    ) external virtual onlyAdmin {
        if (holdingValueSftId_ > 0) {
            require(IERC3525(sft_).slotOf(holdingValueSftId_) == slot_, "SolvBTCMinter: slot does not match");
        }

        SftSlotInfo storage sftSlotInfo = _sftSlotInfos[sft_][slot_];
        sftSlotInfo.oracle = oracle_;
        sftSlotInfo.holdingValueSftId = holdingValueSftId_;
        sftSlotInfo.allowed = allowed_;
        emit SetSftSlot(sft_, slot_, oracle_, holdingValueSftId_, allowed_);
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
