// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IOpenFundMarket {
    function subscribe(bytes32 poolId, uint256 currencyAmount, uint256 openFundShareId, uint64 expireTime) 
        external returns (uint256 value); 
}