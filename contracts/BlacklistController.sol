// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {AdminControlUpgradeable} from "./access/AdminControlUpgradeable.sol";
import {BlacklistableUpgradeable} from "./access/BlacklistableUpgradeable.sol";

contract BlacklistController is AdminControlUpgradeable {

    struct BlacklistSetterConfig {
        uint256 maxBlacklistCount;
        uint256 usedBlacklistCount;
    }

    /// @custom:storage-location erc7201:solv.storage.BlacklistController
    struct BlacklistControllerStorage {
        address _solvBTC;
        mapping(address => bool) _blacklistSetters;
        mapping(address => bool) _blacklistRemovers;
        mapping(address => BlacklistSetterConfig) _blacklistSetterConfigs;
        uint256 _defaultMaxBlacklistCount;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.BlacklistController")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant BlacklistControllerStorageLocation =
        0x95c0e84c0376b603ca83b66a04884ba5aa877db6b87decf45da33717f528af00;

    function _getBlacklistControllerStorage() private pure returns (BlacklistControllerStorage storage $) {
        assembly {
            $.slot := BlacklistControllerStorageLocation
        }
    }

    error InvalidAdmin();
    error InvalidSolvBTC();
    error InvalidDefaultMaxBlacklistCount();
    error InvalidTarget();
    error NotBlacklistSetter(address setter);
    error NotBlacklistRemover(address operator);
    error BlacklistQuotaReached(address setter);
    error AlreadyBlacklisted(address target);
    error NotBlacklisted(address target);

    event DefaultMaxBlacklistCountUpdated(uint256 oldValue, uint256 newValue);
    event BlacklistSetterGranted(address indexed setter, uint256 maxBlacklistCount, uint256 usedBlacklistCount);
    event BlacklistSetterRevoked(address indexed setter);
    event BlacklistRemoverGranted(address indexed operator);
    event BlacklistRemoverRevoked(address indexed operator);
    event BlacklistExecuted(address indexed setter, address indexed target, uint256 usedBlacklistCount);
    event UnblacklistExecuted(address indexed operator, address indexed target);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyBlacklistSetter() {
        if (!isBlacklistSetter(msg.sender)) {
            revert NotBlacklistSetter(msg.sender);
        }
        _;
    }

    modifier onlyBlacklistRemover() {
        if (!isBlacklistRemover(msg.sender)) {
            revert NotBlacklistRemover(msg.sender);
        }
        _;
    }

    function initialize(address solvBTC_, address admin_, uint256 defaultMaxBlacklistCount_) external initializer {
        if (solvBTC_ == address(0)) {
            revert InvalidSolvBTC();
        }
        if (admin_ == address(0)) {
            revert InvalidAdmin();
        }
        
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        $._solvBTC = solvBTC_;
        __AdminControl_init(admin_);
        _setDefaultMaxBlacklistCount(defaultMaxBlacklistCount_);
    }

    function grantBlacklistSetter(address setter, uint256 maxBlacklistCount, bool resetUsedBlacklistCount) 
        external 
        onlyAdmin 
    {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        BlacklistSetterConfig storage setterConfig = $._blacklistSetterConfigs[setter];
        $._blacklistSetters[setter] = true;

        if (maxBlacklistCount == 0) {
            maxBlacklistCount = $._defaultMaxBlacklistCount;
        }
        setterConfig.maxBlacklistCount = maxBlacklistCount;
        
        if (resetUsedBlacklistCount) {
            setterConfig.usedBlacklistCount = 0;
        }

        emit BlacklistSetterGranted(setter, maxBlacklistCount, setterConfig.usedBlacklistCount);
    }

    function revokeBlacklistSetter(address setter) external onlyAdmin {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        $._blacklistSetters[setter] = false;
        emit BlacklistSetterRevoked(setter);
    }

    function grantBlacklistRemover(address operator) external onlyAdmin {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        $._blacklistRemovers[operator] = true;
        emit BlacklistRemoverGranted(operator);
    }

    function revokeBlacklistRemover(address operator) external onlyAdmin {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        $._blacklistRemovers[operator] = false;
        emit BlacklistRemoverRevoked(operator);
    }

    function setDefaultMaxBlacklistCount(uint256 defaultMaxBlacklistCount) external onlyAdmin {
        _setDefaultMaxBlacklistCount(defaultMaxBlacklistCount);
    }

    function blacklist(address target) external onlyBlacklistSetter {
        if (target == address(0)) {
            revert InvalidTarget();
        }

        if (solvBTC().isBlacklisted(target)) {
            revert AlreadyBlacklisted(target);
        }

        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        BlacklistSetterConfig storage setterConfig = $._blacklistSetterConfigs[msg.sender];
        if (setterConfig.usedBlacklistCount >= setterConfig.maxBlacklistCount) {
            revert BlacklistQuotaReached(msg.sender);
        }
        
        solvBTC().addBlacklist(target);
        setterConfig.usedBlacklistCount += 1;

        emit BlacklistExecuted(msg.sender, target, setterConfig.usedBlacklistCount);
    }

    function unblacklist(address target) external onlyBlacklistRemover {
        if (target == address(0)) {
            revert InvalidTarget();
        }
        if (!solvBTC().isBlacklisted(target)) {
            revert NotBlacklisted(target);
        }

        solvBTC().removeBlacklist(target);
        emit UnblacklistExecuted(msg.sender, target);
    }

    function solvBTC() public view returns (BlacklistableUpgradeable) {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        return BlacklistableUpgradeable($._solvBTC);
    }

    function isBlacklistSetter(address setter) public view returns (bool) {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        return $._blacklistSetters[setter];
    }

    function isBlacklistRemover(address operator) public view returns (bool) {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        return $._blacklistRemovers[operator];
    }

    function getBlacklistSetterStatus(address setter)
        public
        view
        returns (bool enabled, uint256 maxBlacklistCount, uint256 usedBlacklistCount)
    {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        BlacklistSetterConfig storage setterConfig = $._blacklistSetterConfigs[setter];
        return (
            $._blacklistSetters[setter], 
            setterConfig.maxBlacklistCount, 
            setterConfig.usedBlacklistCount
        );
    }

    function _setDefaultMaxBlacklistCount(uint256 defaultMaxBlacklistCount) internal {
        if (defaultMaxBlacklistCount == 0) {
            revert InvalidDefaultMaxBlacklistCount();
        }
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        uint256 oldValue = $._defaultMaxBlacklistCount;
        $._defaultMaxBlacklistCount = defaultMaxBlacklistCount;
        emit DefaultMaxBlacklistCountUpdated(oldValue, defaultMaxBlacklistCount);
    }

    function _isBlacklistQuotaReached(address setter) internal view returns (bool) {
        BlacklistControllerStorage storage $ = _getBlacklistControllerStorage();
        BlacklistSetterConfig storage setterConfig = $._blacklistSetterConfigs[setter];
        return setterConfig.usedBlacklistCount >= setterConfig.maxBlacklistCount;
    }

}
