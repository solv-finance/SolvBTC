// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../ISolvBTCYieldTokenOracle.sol";

/**
 * @title XSolvBTCOracle
 * @notice The oracle for xSolvBTC, which is a yield token of solvBTC.
 * @dev This contract is a oracle that allows users to get the nav of xSolvBTC.
 * @dev The nav is the price of xSolvBTC in solvBTC.
 * @dev The nav is updated by the owner at a fixed period of time, such as a week.
 * @dev Only the nav is allowed per day.
 */
contract XSolvBTCOracle is ISolvBTCYieldTokenOracle, Ownable2StepUpgradeable {

    struct XSolvBTCOracleStorage {
        uint8 navDecimals;
        address xSolvBTC;
        uint256 latestNav;
        uint256 latestUpdatedAt;
    }

    // keccak256(abi.encode(uint256(keccak256("solv.storage.xSolvBTCOracle")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant XSolvBTCOracleStorageLocation = 
        0xe699987a594d9368cbcce94ab9df9ac0e935b8cc6f6360cc1af52fdf2ef3a500;

    function _getXSolvBTCOracleStorage() private pure returns (XSolvBTCOracleStorage storage $) {
        assembly {
            $.slot := XSolvBTCOracleStorageLocation
        }
    }

    event SetNav(uint256 navTime, uint256 nav);

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the oracle
     * @param navDecimals_ The decimals of the nav
     */
    function initialize(uint8 navDecimals_) external initializer {
        __Ownable_init(msg.sender);
        _setNavDecimals(navDecimals_);
    }

    /**
     * @notice Get the nav of xSolvBTC
     * @param erc20_ The address of the erc20 token
     * @return latestNav_ Nav The nav of xSolvBTC
     */
    function getNav(address erc20_) external view override returns (uint256 latestNav_) {
        XSolvBTCOracleStorage storage $ = _getXSolvBTCOracleStorage();
        require(erc20_ == $.xSolvBTC, "XSolvBTCOracle: invalid erc20 address");
        latestNav_ = $.latestNav;
        require(latestNav_ != 0, "XSolvBTCOracle: nav not set");
        return latestNav_;
    }

    /**
     * @notice Get the decimals of the nav
     * @param erc20_ The address of the erc20 token
     * @return decimals The decimals of the nav
     */
    function navDecimals(address erc20_) external view override returns (uint8) {
        XSolvBTCOracleStorage storage $ = _getXSolvBTCOracleStorage();
        require(erc20_ == $.xSolvBTC, "XSolvBTCOracle: invalid erc20 address");
        return $.navDecimals;
    }

    /**
     * @notice Get the latest updated at
     * @return latestUpdatedAt The latest updated at
     */
    function latestUpdatedAt() external view returns (uint256) {
        XSolvBTCOracleStorage storage $ = _getXSolvBTCOracleStorage();
        return $.latestUpdatedAt;
    }

    /**
     * @notice Set the nav of xSolvBTC
     * @param nav_ The nav of xSolvBTC
     */
    function setNav(uint256 nav_) external onlyOwner {
        require(nav_ != 0, "XSolvBTCOracle: invalid nav");
        XSolvBTCOracleStorage storage $ = _getXSolvBTCOracleStorage();
        $.latestNav = nav_;
        $.latestUpdatedAt = block.timestamp;
        emit SetNav($.latestUpdatedAt, nav_);
    }

    /**
     * @notice Set the xSolvBTC address
     * @param xSolvBTC_ The address of the xSolvBTC
     */
    function setXSolvBTC(address xSolvBTC_) external onlyOwner {
        XSolvBTCOracleStorage storage $ = _getXSolvBTCOracleStorage();
        $.xSolvBTC = xSolvBTC_;
    }

    function _setNavDecimals(uint8 navDecimals_) internal {
        XSolvBTCOracleStorage storage $ = _getXSolvBTCOracleStorage();
        $.navDecimals = navDecimals_;
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
