// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {SolvBTCV2_1} from "./SolvBTCV2_1.sol";
import {BlacklistableUpgradeable} from "./access/BlacklistableUpgradeable.sol";

/**
 * @title Implementation for SolvBTC V3, which is inherited from SolvBTC V2.1 and expanded with 
 * blacklist functionality.
 * @custom:security-contact dev@solv.finance
 */
contract SolvBTCV3 is SolvBTCV2_1, BlacklistableUpgradeable {

    /**
     * @dev Account is not blacklisted.
     */
    error SolvBTCNotBlacklisted(address account);

    /// @notice Emitted when black funds are destroyed.
    event DestroyBlackFunds(address indexed account, uint256 amount);

    /// @notice Destroys black funds from the specified blacklist account.
    function destroyBlackFunds(address account, uint256 amount) external virtual onlyOwner {
        if (!isBlacklisted(account)) {
            revert SolvBTCNotBlacklisted(account);
        }
        super._update(account, address(0), amount);
        emit DestroyBlackFunds(account, amount);
    }

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
        notBlacklisted(msg.sender)
    {
        super._update(from, to, value);
    }
}
