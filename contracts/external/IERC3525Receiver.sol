// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC3525Receiver {
    function onERC3525Received(address operator, uint256 fromTokenId, uint256 toTokenId, uint256 value, bytes calldata data) external returns (bytes4);
}
