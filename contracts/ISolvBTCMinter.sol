// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISolvBTCMinter {
    function mint(address sft_, uint256 sftId_, uint256 value_) external;
    function burn(address sft, uint256 sftId, uint256 slot, uint256 value) external returns (uint256 toSftId_);
    function isSftSlotAllowed(address sft_, uint256 slot_) external view returns (bool);
    function getSftSlotBalance(address sft_, uint256 slot_) external view returns (uint256);
}