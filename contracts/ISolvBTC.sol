// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./external/IERC721Receiver.sol";
import "./external/IERC3525Receiver.sol";

interface ISolvBTC is IERC20, IERC721Receiver, IERC3525Receiver, IERC165 {

    error ERC721NotReceivable(address token);
    error ERC3525NotReceivable(address token);

    function mint(address account, uint256 value) external;
    function burn(address account, uint256 value) external;

    function solvBTCMultiAssetPool() external view returns (address);
}