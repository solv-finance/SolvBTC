// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract CallerControlUpgradeable is Initializable {

    struct CallerControlStorage {
        mapping(address => bool) _allowedCallers;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.CallerControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant CallerControlStorageLocation = 0xad628aca6c9727ccf1ca6e8cdfd433936675fd6821d38fcb0b7860e090bead00;

    function _getCallerControlStorage() private pure returns (CallerControlStorage storage $) {
        assembly {
            $.slot := CallerControlStorageLocation
        }
    }

    event AllowedCallerChanged(address indexed caller, bool allowed);

    modifier onlyAllowedCaller() {
        require(isCallerAllowed(msg.sender), "CallerControl: caller not allowed");
        _;
    }

    function __CallerControl_init() internal onlyInitializing {
    }

    function __CallerControl_init_unchained() internal onlyInitializing {
    }

    function isCallerAllowed(address caller) public view returns (bool) {
        return _getCallerControlStorage()._allowedCallers[caller];
    }

    function _setCallerAllowed(address caller, bool allowed) internal {
        _getCallerControlStorage()._allowedCallers[caller] = allowed;
        emit AllowedCallerChanged(caller, allowed);
    }
}