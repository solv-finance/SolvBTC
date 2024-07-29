// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function approve(address approved, uint256 tokenId) external payable;
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenId) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;
    function safeTransferFrom(address from, address to, uint256 tokenId) external payable;
}
