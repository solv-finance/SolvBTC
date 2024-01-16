// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

interface IERC3525 is IERC721 {
    function valueDecimals() external view returns (uint8);
    function balanceOf(uint256 tokenId) external view returns (uint256);
    function slotOf(uint256 tokenId) external view returns (uint256);
    function allowance(uint256 tokenId, address operator) external view returns (uint256);
    
    function approve(address operator, uint256 tokenId) external payable;
    function approve(uint256 tokenId, address operator, uint256 value) external payable;
    function transferFrom(uint256 fromTokenId, uint256 toTokenId, uint256 value) external payable;
    function transferFrom(uint256 fromTokenId, address to, uint256 value) external payable returns (uint256);
}
