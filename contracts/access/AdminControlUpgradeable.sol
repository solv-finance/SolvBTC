// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract AdminControlUpgradeable is Initializable {
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    address public admin;
    address public pendingAdmin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyPendingAdmin() {
        require(msg.sender == pendingAdmin, "only pending admin");
        _;
    }

    function __AdminControl_init(address admin_) internal onlyInitializing {
        __AdminControl_init_unchained(admin_);
    }

    function __AdminControl_init_unchained(address admin_) internal onlyInitializing {
        admin = admin_;
        emit NewAdmin(address(0), admin_);
    }

    function transferAdmin(address newPendingAdmin_) external virtual onlyAdmin {
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin_);
        pendingAdmin = newPendingAdmin_;
    }

    function acceptAdmin() external virtual onlyPendingAdmin {
        emit NewAdmin(admin, pendingAdmin);
        emit NewPendingAdmin(pendingAdmin, address(0));
        admin = pendingAdmin;
        delete pendingAdmin;
    }

    uint256[48] private __gap;
}
