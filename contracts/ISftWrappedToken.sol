// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISftWrappedToken is IERC20 {
	function mint(uint256 sftId_, uint256 amount_) external;
    function burn(uint256 amount_, uint256 sftId_) external;
    function getValueByShares(uint256 shares) external view returns (uint256 value);
    function getSharesByValue(uint256 value) external view returns (uint256 shares);
    function underlyingAsset() external view returns (address underlyingAsset);
}