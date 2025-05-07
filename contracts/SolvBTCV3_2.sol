// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {SolvBTCV3_1} from "./SolvBTCV3_1.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

/**
 * @title Implementation for SolvBTC V3_1, which is inherited from SolvBTC V3 and expanded with
 * openzeppelin pausable functionality.
 * @custom:security-contact dev@solv.finance
 */
contract SolvBTCV3_2 is SolvBTCV3_1 {
    event SetAlias(string name, string symbol);

    struct AliasStorage {
        string _name;
        string _symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCV3_2")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ALIAS_STORAGE_POSITION = 0xb49717cac156ec86bd7b6b0fea944433f4c25ca475d03187c6d407e07915fd00;

    function _getAliasStorage() private pure returns (AliasStorage storage $) {
        assembly {
            $.slot := ALIAS_STORAGE_POSITION
        }
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        AliasStorage storage $ = _getAliasStorage();
        if (bytes($._name).length == 0) {
            return super.name();
        }
        return $._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        AliasStorage storage $ = _getAliasStorage();
        if (bytes($._symbol).length == 0) {
            return super.symbol();
        }
        return $._symbol;
    }

    /**
     * @dev Sets the alias name and symbol of the SolvBTC yield token.
     */
    function setAlias(string calldata name_, string calldata symbol_) external virtual onlyOwner {
        AliasStorage storage $ = _getAliasStorage();
        $._name = name_;
        $._symbol = symbol_;
        emit SetAlias(name_, symbol_);
    }
}
