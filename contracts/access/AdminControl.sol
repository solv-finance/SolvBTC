// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract AdminControl {

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

    constructor(address admin_) {
        admin = admin_;
        emit NewAdmin(address(0), admin_);
    }

    function transferAdmin(address newPendingAdmin_) external virtual onlyAdmin {
        emit NewPendingAdmin(pendingAdmin, newPendingAdmin_);
        pendingAdmin = newPendingAdmin_;        
    }

    function acceptAdmin() external virtual onlyPendingAdmin {
        emit NewAdmin(admin, pendingAdmin);
        admin = pendingAdmin;
        delete pendingAdmin;
    }
}
