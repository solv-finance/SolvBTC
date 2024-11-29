// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./SolvBTC.sol";
import "./access/BlacklistableUpgradeable.sol";

contract SolvBTCV2 is SolvBTC, BlacklistableUpgradeable {
    event DestroyBlackFunds(address indexed account, uint256 amount);

    function _approve(address owner, address spender, uint256 value, bool emitEvent)
        internal
        virtual
        override
        notBlacklisted(spender)
        notBlacklisted(owner)
    {
        super._approve(owner, spender, value, emitEvent);
    }

    function _update(address from, address to, uint256 value)
        internal
        virtual
        override
        notBlacklisted(from)
        notBlacklisted(to)
    {
        super._update(from, to, value);
    }

    function destroyBlackFunds(address account, uint256 amount) external virtual onlyOwner {
        require(_blacklisted[account], "SolvBTCV2: account is not blacklisted");
        super._update(account, address(0), amount);
        emit DestroyBlackFunds(account, amount);
    }

    uint256[50] private __gap;
}
