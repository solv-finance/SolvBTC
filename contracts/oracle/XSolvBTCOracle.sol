// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../ISolvBTCYieldTokenOracle.sol";
import "../access/AdminControlUpgradeable.sol";

/**
 * @title XSolvBTCOracle
 * @notice The oracle for xSolvBTC, which is a yield token of solvBTC.
 * @dev This contract is a oracle that allows users to get the nav of xSolvBTC.
 * @dev The nav is the price of xSolvBTC in solvBTC.
 * @dev The nav is updated by the admin at a fixed period of time, such as a week.
 * @dev Only the nav is allowed per day.
 */
contract XSolvBTCOracle is ISolvBTCYieldTokenOracle, AdminControlUpgradeable {
    uint8 private _navDecimals;
    address public xSolvBTC;
    uint256 private _latestUpdatedAt;
    uint256 private _latestNav;

    event SetNav(uint256 navTime, uint256 nav);

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the oracle
     * @param navDecimals_ The decimals of the nav
     */
    function initialize(uint8 navDecimals_) external initializer {
        __AdminControl_init(msg.sender);
        _navDecimals = navDecimals_;
    }

    /**
     * @notice Get the nav of xSolvBTC
     * @param erc20_ The address of the erc20 token
     * @return nav The nav of xSolvBTC
     */
    function getNav(address erc20_) external view override returns (uint256) {
        require(erc20_ == xSolvBTC, "XSolvBTCOracle: invalid erc20 address");
        require(_latestNav != 0, "XSolvBTCOracle: nav not set");
        return _latestNav;
    }

    /**
     * @notice Get the decimals of the nav
     * @param erc20_ The address of the erc20 token
     * @return decimals The decimals of the nav
     */
    function navDecimals(address erc20_) external view override returns (uint8) {
        require(erc20_ == xSolvBTC, "XSolvBTCOracle: invalid erc20 address");
        return _navDecimals;
    }

    /**
     * @notice Get the latest updated at
     * @return latestUpdatedAt The latest updated at
     */
    function latestUpdatedAt() external view returns (uint256) {
        return _latestUpdatedAt;
    }

    /**
     * @notice Set the nav of xSolvBTC
     * @param nav_ The nav of xSolvBTC
     */
    function setNav(uint256 nav_) external onlyAdmin {
        require(nav_ != 0, "XSolvBTCOracle: invalid nav");
        require(nav_ >= _latestNav, "XSolvBTCOracle: nav is not increasing");
        _latestNav = nav_;
        _latestUpdatedAt = block.timestamp;
        emit SetNav(_latestUpdatedAt, nav_);
    }

    /**
     * @notice Set the xSolvBTC address
     * @param xSolvBTC_ The address of the xSolvBTC
     */
    function setXSolvBTC(address xSolvBTC_) external onlyAdmin {
        xSolvBTC = xSolvBTC_;
    }

    /**
     * @notice Get the date of the timestamp
     * @param timestamp_ The timestamp
     * @return date The date
     */
    function _getDate(uint256 timestamp_) internal pure returns (uint256) {
        return timestamp_ / 86400 * 86400;
    }
}
