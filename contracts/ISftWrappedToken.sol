// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./external/IERC721Receiver.sol";
import "./external/IERC3525Receiver.sol";

interface ISftWrappedToken is IERC20, IERC721Receiver, IERC3525Receiver, IERC165 {
	function mint(uint256 sftId_, uint256 amount_) external;
    function burn(uint256 amount_, uint256 sftId_) external returns (uint256 toSftId_);
    function getValueByShares(uint256 shares) external view returns (uint256 value);
    function getSharesByValue(uint256 value) external view returns (uint256 shares);
    function underlyingAsset() external view returns (address underlyingAsset);
}