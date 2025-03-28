// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {SolvBTCV3} from "./SolvBTCV3.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title Implementation for SolvBTC V3_1, which is inherited from SolvBTC V3 and expanded with
 * openzeppelin pausable functionality.
 * @custom:security-contact dev@solv.finance
 */
contract SolvBTCV3_1 is SolvBTCV3, PausableUpgradeable {
    struct SolvBTCV3_1Storage {
        address _pauser;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCV3_1")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCV3_1StorageLocation =
        0x502a85c8d631e3586414f9cb06ca4d27c03b5f40bf43ea12a9183dd747be5900;

    /**
     * @dev Operates by non pauser.
     */
    error PausablePauser(address account);

    function _getSolvBTCV3_1Storage() private pure returns (SolvBTCV3_1Storage storage $) {
        assembly {
            $.slot := SolvBTCV3_1StorageLocation
        }
    }

    /**
     * @dev throws if called by any account other than the pauser
     */
    modifier onlyPauser() {
        SolvBTCV3_1Storage storage $ = _getSolvBTCV3_1Storage();
        if (msg.sender != $._pauser) {
            revert PausablePauser(msg.sender);
        }
        _;
    }

    function setPauser(address pauser) external onlyOwner {
        SolvBTCV3_1Storage storage $ = _getSolvBTCV3_1Storage();
        $._pauser = pauser;
    }

    function pause() external onlyPauser whenNotPaused {
        _pause();
    }

    function unpause() external onlyPauser whenPaused {
        _unpause();
    }

    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}
