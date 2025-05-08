// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../ISolvBTCYieldTokenOracle.sol";
import "../access/AdminControlUpgradeable.sol";

contract XSolvBTCOracle is ISolvBTCYieldTokenOracle, AdminControlUpgradeable {
    uint256 private _currentNav;
    uint8 private _navDecimals;
    address public xSolvBTC;

    event SetCurrentNav(uint256 oldCurrentNav, uint256 newCurrentNav);

    function initialize(uint256 currentNav_, uint8 navDecimals_) external initializer {
        __AdminControl_init(msg.sender);
        _currentNav = currentNav_;
        _navDecimals = navDecimals_;
    }

    function getNav(address erc20_) external view override returns (uint256) {
        require(erc20_ == xSolvBTC, "XSolvBTCOracle: invalid erc20 address");
        return _currentNav;
    }

    function navDecimals(address erc20_) external view override returns (uint8) {
        require(erc20_ == xSolvBTC, "XSolvBTCOracle: invalid erc20 address");
        return _navDecimals;
    }

    function setCurrentNav(uint256 currentNav_) external onlyAdmin {
        uint256 oldCurrentNav = _currentNav;
        _currentNav = currentNav_;
        emit SetCurrentNav(oldCurrentNav, currentNav_);
    }

    function setXSolvBTC(address xSolvBTC_) external onlyAdmin {
        xSolvBTC = xSolvBTC_;
    }
}
