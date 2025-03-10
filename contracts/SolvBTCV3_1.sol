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

    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }

    function _update(address from, address to, uint256 value) internal virtual override whenNotPaused {
        super._update(from, to, value);
    }
}
