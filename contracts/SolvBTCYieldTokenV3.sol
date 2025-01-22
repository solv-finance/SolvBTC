// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SolvBTCYieldTokenV2_1.sol";
import "./SolvBTCV3.sol";

contract SolvBTCYieldTokenV3 is SolvBTCYieldTokenV2_1, SolvBTCV3 {

    function _approve(address owner, address spender, uint256 value, bool emitEvent)
        internal
        virtual
        override(ERC20Upgradeable, SolvBTCV3)
    {
        SolvBTCV3._approve(owner, spender, value, emitEvent);
    }

    function _update(address from, address to, uint256 value)
        internal
        virtual
        override(ERC20Upgradeable, SolvBTCV3)
    {
        SolvBTCV3._update(from, to, value);
    } 

}
