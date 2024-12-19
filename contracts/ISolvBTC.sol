// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Receiver} from "./external/IERC721Receiver.sol";
import {IERC3525Receiver} from "./external/IERC3525Receiver.sol";

/**
 * @title Interface for SolvBTC.
 * @custom:security-contact dev@solv.finance
 */
interface ISolvBTC is IERC20, IERC721Receiver, IERC3525Receiver, IERC165 {

    error ERC721NotReceivable(address token);
    error ERC3525NotReceivable(address token);

    function mint(address account_, uint256 value_) external;
    function burn(address account_, uint256 value_) external;
    function burn(uint256 value_) external;
}