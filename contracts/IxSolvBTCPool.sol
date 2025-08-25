// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IxSolvBTCPool {
    function deposit(uint256 solvBtcAmount_) external returns (uint256 xSolvBtcAmount);
    function withdraw(uint256 xSolvBtcAmount_) external returns (uint256 solvBtcAmount);
}
