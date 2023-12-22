// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IERC3525Receiver {
    function onERC3525Received(address operator, uint256 fromTokenId, uint256 toTokenId, uint256 value, bytes calldata data) external returns (bytes4);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface ISftWrappedToken is IERC20, IERC721Receiver, IERC3525Receiver, IERC165 {
	function mint(uint256 sftId_, uint256 amount_) external;
    function burn(uint256 amount_, uint256 sftId_) external returns (uint256 toSftId_);
    function getValueByShares(uint256 shares) external view returns (uint256 value);
    function getSharesByValue(uint256 value) external view returns (uint256 shares);
    function underlyingAsset() external view returns (address underlyingAsset);
}