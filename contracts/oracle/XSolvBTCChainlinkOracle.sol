// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "../ISolvBTCYieldTokenOracle.sol";
import "../access/AdminControlUpgradeable.sol";

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

/**
 * @title ChainlinkOracle
 * @notice The oracle for xSolvBTC, which is a yield token of SolvBTC.
 * @dev This contract is an oracle that allows users to get the nav of xSolvBTC.
 * @dev The nav is the price of xSolvBTC in SolvBTC.
 * @dev The nav is obtained from the chainlink oracle.
 */
contract XSolvBTCChainlinkOracle is ISolvBTCYieldTokenOracle, AdminControlUpgradeable {

    // The address of xSolvBTC
    address public xSolvBTC;

    // The address of the chainlink aggregator for xSolvBTC
    address public aggregator;

    event SetXSolvBTC(address indexed xSolvBTC);
    event SetAggregator(address indexed aggregator);

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract
     * @param aggregator_ The address of the chainlink aggregator for xSolvBTC
     */
    function initialize(address aggregator_) external initializer {
        __AdminControl_init(msg.sender);
        _setAggregator(aggregator_);
    }

    /**
     * @notice Get the nav of xSolvBTC
     * @param erc20_ The address of the erc20 token
     * @return nav The nav of xSolvBTC
     */
    function getNav(address erc20_) external view override returns (uint256 nav) {
        require(erc20_ == xSolvBTC, "XSolvBTCChainlinkOracle: invalid erc20 address");
        (, int256 answer, , , ) = AggregatorV3Interface(aggregator).latestRoundData();
        require(answer > 0, "XSolvBTCChainlinkOracle: invalid nav value");
        nav = uint256(answer);
    }

    /**
     * @notice Get the decimals of the nav
     * @param erc20_ The address of the erc20 token
     * @return decimals The decimals of the nav
     */
    function navDecimals(address erc20_) external view override returns (uint8) {
        require(erc20_ == xSolvBTC, "XSolvBTCChainlinkOracle: invalid erc20 address");
        return AggregatorV3Interface(aggregator).decimals();
    }

    /**
     * @notice Get the latest update time of the nav
     * @return latestUpdatedAt The latest update time of the nav
     */
    function latestUpdatedAt() external view returns (uint256) {
        (, , , uint256 updatedAt, ) = AggregatorV3Interface(aggregator).latestRoundData();
        return updatedAt;
    }

    /**
     * @notice Set the xSolvBTC address
     * @param xSolvBTC_ The address of the xSolvBTC
     */
    function setXSolvBTC(address xSolvBTC_) external onlyAdmin {
        require(xSolvBTC_ != address(0), "XSolvBTCChainlinkOracle: invalid xSolvBTC address");
        xSolvBTC = xSolvBTC_;
        emit SetXSolvBTC(xSolvBTC_);
    }

    /**
     * @notice Set the chainlink aggregator address
     * @param aggregator_ The address of the chainlink aggregator
     */
    function setAggregator(address aggregator_) external onlyAdmin {
        _setAggregator(aggregator_);
    }

    /**
     * @notice Set the chainlink aggregator address
     * @param aggregator_ The address of the chainlink aggregator
     */
    function _setAggregator(address aggregator_) internal {
        require(aggregator_ != address(0), "XSolvBTCChainlinkOracle: invalid aggregator address");
        aggregator = aggregator_;
        emit SetAggregator(aggregator_);
    }

    uint256[48] private __gap;
}
