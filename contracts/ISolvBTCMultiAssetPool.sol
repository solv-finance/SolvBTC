// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface ISolvBTCMultiAssetPool {
    function deposit(address sft_, uint256 sftId_, uint256 value_) external;
    function withdraw(address sft, uint256 slot, uint256 sftId, uint256 value) external returns (uint256 toSftId_);

    function isSftSlotDepositAllowed(address sft_, uint256 slot_) external view returns (bool);
    function isSftSlotWithdrawAllowed(address sft_, uint256 slot_) external view returns (bool);
    function getERC20(address sft_, uint256 slot_) external view returns (address);
    function getHoldingValueSftId(address sft_, uint256 slot_) external view returns (uint256);
    function getSftSlotBalance(address sft_, uint256 slot_) external view returns (uint256);
}
