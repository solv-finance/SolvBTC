// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SolvBTCYieldTokenV3.sol";
import "./SolvBTCV3_1.sol";

contract SolvBTCYieldTokenV3_1 is SolvBTCYieldTokenV3, SolvBTCV3_1 {

    event SetAlias(string name, string symbol);

    struct AliasStorage {
        string _name;
        string _symbol;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.SolvBTCYieldTokenV3_1")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ALIAS_STORAGE_POSITION = 0xda2596346793476faa39ef2fc6f6928de90d835de448231a9734d2e32c5b1400;

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

    function _approve(address owner, address spender, uint256 value, bool emitEvent)
        internal
        virtual
        override(SolvBTCYieldTokenV3, SolvBTCV3)
    {
        SolvBTCV3._approve(owner, spender, value, emitEvent);
    }

    function _update(address from, address to, uint256 value)
        internal
        virtual
        override(SolvBTCYieldTokenV3, SolvBTCV3_1)
    {
        SolvBTCV3_1._update(from, to, value);
    }
}
