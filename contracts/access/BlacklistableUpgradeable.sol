// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/**
 * @title Blacklistable
 * @dev Allows accounts to be blacklisted by a "blacklist manager" role
 */
abstract contract BlacklistableUpgradeable is Ownable2StepUpgradeable {
    address public blacklistManager;
    mapping(address => bool) internal _blacklisted;

    event BlacklistAdded(address indexed _account);
    event BlacklistRemoved(address indexed _account);
    event BlacklistManagerChanged(address indexed newBlacklistManager);

    /**
     * @dev Throws if called by any account other than the blacklist manager.
     */
    modifier onlyBlacklistManager() {
        require(msg.sender == blacklistManager, "Blacklistable: caller is not the blacklist manager");
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted.
     * @param _account The address to check.
     */
    modifier notBlacklisted(address _account) {
        require(!_isBlacklisted(_account), "Blacklistable: account is blacklisted");
        _;
    }

    /**
     * @notice Checks if account is blacklisted.
     * @param _account The address to check.
     * @return True if the account is blacklisted, false if the account is not blacklisted.
     */
    function isBlacklisted(address _account) external view returns (bool) {
        return _isBlacklisted(_account);
    }

    /**
     * @notice Adds account to blacklist.
     * @param _account The address to blacklist.
     */
    function addBlacklist(address _account) external onlyBlacklistManager {
        _addBlacklist(_account);
        emit BlacklistAdded(_account);
    }

    function addBlacklistBatch(address[] memory _accounts) external onlyBlacklistManager {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _addBlacklist(_accounts[i]);
            emit BlacklistAdded(_accounts[i]);
        }
    }

    /**
     * @notice Removes account from blacklist.
     * @param _account The address to remove from the blacklist.
     */
    function removeBlacklist(address _account) external onlyBlacklistManager {
        _removeBlacklist(_account);
        emit BlacklistRemoved(_account);
    }

    function removeBlacklistBatch(address[] memory _accounts) external onlyBlacklistManager {
        for (uint256 i = 0; i < _accounts.length; i++) {
            _removeBlacklist(_accounts[i]);
            emit BlacklistRemoved(_accounts[i]);
        }
    }

    /**
     * @notice Updates the blacklist manager address.
     * @param _newBlacklistManager The address of the new blacklist manager.
     */
    function updateBlacklistManager(address _newBlacklistManager) external onlyOwner {
        require(_newBlacklistManager != address(0), "Blacklistable: new blacklist manager is the zero address");
        blacklistManager = _newBlacklistManager;
        emit BlacklistManagerChanged(blacklistManager);
    }

    /**
     * @dev Checks if account is blacklisted.
     * @param _account The address to check.
     * @return true if the account is blacklisted, false otherwise.
     */
    function _isBlacklisted(address _account) internal view virtual returns (bool) {
        return _blacklisted[_account];
    }

    /**
     * @dev Helper method that blacklists an account.
     * @param _account The address to blacklist.
     */
    function _addBlacklist(address _account) internal virtual {
        _blacklisted[_account] = true;
    }

    /**
     * @dev Helper method that unblacklists an account.
     * @param _account The address to unblacklist.
     */
    function _removeBlacklist(address _account) internal virtual {
        _blacklisted[_account] = false;
    }

    uint256[45] private __gap;
}
