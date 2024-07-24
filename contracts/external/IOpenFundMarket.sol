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
    function subscribe(bytes32 poolId, uint256 currencyAmount, uint256 openFundShareId, uint64 expireTime)
        external
        returns (uint256 value_);
    function requestRedeem(bytes32 poolId, uint256 openFundShareId, uint256 openFundRedemptionId, uint256 redeemValue)
        external;
    function revokeRedeem(bytes32 poolId, uint256 openFundRedemptionId) external;

    function poolInfos(bytes32 poolId) external view returns (PoolInfo memory);
    function getAddress(bytes32 name) external view returns (address);
    function purchasedRecords(bytes32 poolId, address buyer) external view returns (uint256);
}

interface IOFMWhitelistStrategyManager {
    function isWhitelisted(bytes32 poolId_, address buyer_) external view returns (bool);
}
