// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface ISolvBTCYieldTokenOracle {
    function getNav(address erc20) external view returns (uint256);
    function navDecimals(address erc20) external view returns (uint8);
}
