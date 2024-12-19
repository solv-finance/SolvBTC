// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

/**
 * @title Blacklistable
 * @dev Allows accounts to be blacklisted by a "blacklist manager" role
 */
abstract contract BlacklistableUpgradeable is Ownable2StepUpgradeable {

    /// @custom:storage-location erc7201:solv.storage.Blacklistable
    struct BlacklistableStorage {
        mapping(address => bool) _blacklisted;
        address _blacklistManager;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.Blacklistable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant SolvBTCStorageLocation = 0x37055a6a5ad221b3685065a6f80bdaf8b5de26b2f60e82c3fbc16e3374b00c00;

    event BlacklistAdded(address indexed account_);
    event BlacklistRemoved(address indexed account_);
    event BlacklistManagerChanged(address indexed newBlacklistManager);

    /**
     * @dev Throws if called by any account other than the blacklist manager.
     */
    modifier onlyBlacklistManager() {
        require(msg.sender == blacklistManager(), "Blacklistable: caller is not the blacklist manager");
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted.
     * @param account_ The address to check.
     */
    modifier notBlacklisted(address account_) {
        require(!isBlacklisted(account_), "Blacklistable: account is blacklisted");
        _;
    }

    function _getBlacklistableStorage() internal pure returns (BlacklistableStorage storage $) {
        assembly {
            $.slot := SolvBTCStorageLocation
        }
    }

    /**
     * @notice Checks if account is blacklisted.
     * @param account_ The address to check.
     * @return True if the account is blacklisted, false if the account is not blacklisted.
     */
    function isBlacklisted(address account_) public view returns (bool) {
        BlacklistableStorage storage $ = _getBlacklistableStorage();
        return $._blacklisted[account_];
    }

    /**
     * @notice Get the address of the blacklist manager.
     */
    function blacklistManager() public view returns (address) {
        BlacklistableStorage storage $ = _getBlacklistableStorage();
        return $._blacklistManager;
    }

    /**
     * @notice Adds account to blacklist.
     * @param account_ The address to blacklist.
     */
    function addBlacklist(address account_) external onlyBlacklistManager {
        _addBlacklist(account_);
    }

    /**
     * @notice Adds multiple accounts to the blacklist.
     * @param accounts_ The addresses to blacklist.
     */
    function addBlacklistBatch(address[] memory accounts_) external onlyBlacklistManager {
        for (uint256 i = 0; i < accounts_.length; i++) {
            _addBlacklist(accounts_[i]);
        }
    }

    /**
     * @notice Removes account from blacklist.
     * @param account_ The address to remove from the blacklist.
     */
    function removeBlacklist(address account_) external onlyBlacklistManager {
        _removeBlacklist(account_);
    }

    /**
     * @notice Removes multiple accounts from the blacklist.
     * @param accounts_ The addresses to remove from the blacklist.
     */
    function removeBlacklistBatch(address[] memory accounts_) external onlyBlacklistManager {
        for (uint256 i = 0; i < accounts_.length; i++) {
            _removeBlacklist(accounts_[i]);
        }
    }

    /**
     * @notice Updates the blacklist manager address.
     * @param newBlacklistManager_ The address of the new blacklist manager.
     */
    function updateBlacklistManager(address newBlacklistManager_) external onlyOwner {
        require(newBlacklistManager_ != address(0), "Blacklistable: invalid blacklist manager");
        BlacklistableStorage storage $ = _getBlacklistableStorage();
        $._blacklistManager = newBlacklistManager_;
        emit BlacklistManagerChanged(newBlacklistManager_);
    }

    /**
     * @dev Helper method that blacklists an account.
     * @param account_ The address to blacklist.
     */
    function _addBlacklist(address account_) internal virtual {
        require(account_ != address(0), "Blacklistable: invalid account");
        BlacklistableStorage storage $ = _getBlacklistableStorage();
        $._blacklisted[account_] = true;
        emit BlacklistAdded(account_);
    }

    /**
     * @dev Helper method that unblacklists an account.
     * @param account_ The address to unblacklist.
     */
    function _removeBlacklist(address account_) internal virtual {
        BlacklistableStorage storage $ = _getBlacklistableStorage();
        $._blacklisted[account_] = false;
        emit BlacklistRemoved(account_);
    }
}
