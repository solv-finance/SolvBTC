// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct SubscribeLimitInfo {
    uint256 hardCap;
    uint256 subscribeMin;
    uint256 subscribeMax;
    uint64 fundraisingStartTime;
    uint64 fundraisingEndTime;
}
struct PoolSFTInfo {
    address openFundShare;
    address openFundRedemption;
    uint256 openFundShareSlot;
    uint256 latestRedeemSlot;
}
struct PoolFeeInfo {
    uint16 carryRate;
    address carryCollector;
    uint64 latestProtocolFeeSettleTime;
}
struct ManagerInfo {
    address poolManager;
    address subscribeNavManager;
    address redeemNavManager;
}
struct PoolInfo {
    PoolSFTInfo poolSFTInfo;
    PoolFeeInfo poolFeeInfo;
    ManagerInfo managerInfo;
    SubscribeLimitInfo subscribeLimitInfo;
    address vault;
    address currency;
    address navOracle;
    uint64 valueDate;
    bool permissionless;
    uint256 fundraisingAmount;
}

interface IOpenFundMarket {

    function subscribe(bytes32 poolId, uint256 currencyAmount, uint256 openFundShareId, uint64 expireTime) external returns (uint256 value_);
    function requestRedeem(bytes32 poolId, uint256 openFundShareId, uint256 openFundRedemptionId, uint256 redeemValue) external;
    function revokeRedeem(bytes32 poolId, uint256 openFundRedemptionId) external;

    function poolInfos(bytes32 poolId) external returns (PoolInfo memory);
}
