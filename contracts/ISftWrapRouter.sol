// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./external/IERC721Receiver.sol";
import "./external/IERC3525Receiver.sol";

interface ISftWrapRouter is IERC721Receiver, IERC3525Receiver, IERC165 {
}