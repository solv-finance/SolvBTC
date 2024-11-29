// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SolvBTCYieldToken.sol";
import "./SolvBTCV2.sol";

contract SolvBTCYieldTokenV2 is SolvBTCYieldToken, SolvBTCV2 {

    function _approve(address owner, address spender, uint256 value, bool emitEvent)
        internal
        virtual
        override(ERC20Upgradeable, SolvBTCV2)
    {
        SolvBTCV2._approve(owner, spender, value, emitEvent);
    }

    function _update(address from, address to, uint256 value)
        internal
        virtual
        override(ERC20Upgradeable, SolvBTCV2)
    {
        SolvBTCV2._update(from, to, value);
    } 

    uint256[50] private __gap;
}
