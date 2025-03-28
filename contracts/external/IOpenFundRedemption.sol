// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

struct RedeemInfo {
    bytes32 poolId;
    address currency;
    uint256 createTime;
    uint256 nav;
}

interface IOpenFundRedemptionDelegate {
    function concrete() external view returns (address);
}

interface IOpenFundRedemptionConcrete {
    function getRedeemInfo(uint256 slot) external view returns (RedeemInfo memory);
}
