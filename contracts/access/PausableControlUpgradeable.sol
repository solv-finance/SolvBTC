// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

contract PausableControlUpgradeable is Initializable, PausableUpgradeable {

	event NewPauseAdmin(address oldPauseAdmin, address newPauseAdmin);
    event NewPendingPauseAdmin(address oldPendingPauseAdmin, address newPendingPauseAdmin);

    struct PausableControlStorage {
        address pauseAdmin;
        address pendingPauseAdmin;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.PausableControl")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant PausableControlStorageLocation = 0x595cc456dec452004b428d6a4fd3fd10e1b183a5540fc2b1ff59ec1f84179200;

    function _getPausableControlStorage() private pure returns (PausableControlStorage storage $) {
        assembly {
            $.slot := PausableControlStorageLocation
        }
    }

    modifier onlyPauseAdmin() {
        PausableControlStorage storage $ = _getPausableControlStorage();
        require(msg.sender == $.pauseAdmin, "only pause admin");
        _;
    }

    function __PausableControl_init(address pauseAdmin_) internal onlyInitializing {
        __PausableControl_init_unchained(pauseAdmin_);
    }

    function __PausableControl_init_unchained(address pauseAdmin_) internal onlyInitializing {
        _getPausableControlStorage().pauseAdmin = pauseAdmin_;
        emit NewPauseAdmin(address(0), pauseAdmin_);
    }

    function pause() external virtual onlyPauseAdmin whenNotPaused {
        _pause();
    }

    function unpause() external virtual onlyPauseAdmin whenPaused {
        _unpause();
    }

    function pauseAdmin() public view virtual returns (address) {
        PausableControlStorage storage $ = _getPausableControlStorage();
        return $.pauseAdmin;
    }

    function pendingPauseAdmin() public view virtual returns (address) {
        PausableControlStorage storage $ = _getPausableControlStorage();
        return $.pendingPauseAdmin;
    }

    function transferPauseAdmin(address newPauseAdmin_) external virtual onlyPauseAdmin {
        PausableControlStorage storage $ = _getPausableControlStorage();
        $.pendingPauseAdmin = newPauseAdmin_;
        emit NewPendingPauseAdmin($.pauseAdmin, newPauseAdmin_);
    }

    function acceptPauseAdmin() external virtual {
        address sender = msg.sender;
        PausableControlStorage storage $ = _getPausableControlStorage();
        require(sender == $.pendingPauseAdmin, "no pending pause admin");
        address oldPauseAdmin = $.pauseAdmin;
        $.pauseAdmin = sender;
        delete $.pendingPauseAdmin;
        emit NewPauseAdmin(oldPauseAdmin, sender);
    }


}