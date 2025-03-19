// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {SolvBTCRouter} from "./SolvBTCRouter.sol";

interface IWrapToken is IERC20 {
    function deposit(uint256 amount) external payable;
}

contract NativeDeposit is ReentrancyGuardUpgradeable {

    address public wrapToken;
    address public solvBTC;
    address public router;

    event Deposit(bytes32 indexed poolId, address indexed sender, uint256 amountIn, uint256 amountOut);

    function initialize(address wrapToken_, address solvBTC_, address router_) external initializer {
        __ReentrancyGuard_init();

        require(wrapToken_ != address(0), "invalid wrapToken");
        require(solvBTC_ != address(0), "invalid solvBTC");
        require(router_ != address(0), "invalid router");

        wrapToken = wrapToken_;
        solvBTC = solvBTC_;
        router = router_;
    }

    function deposit(bytes32 poolId_, uint256 amountIn_) external nonReentrant payable returns (uint256 amountOut_) {
        require(msg.value == amountIn_, "incorrect amount");
        IWrapToken(wrapToken).deposit{value: amountIn_}(amountIn_);
        IWrapToken(wrapToken).approve(router, amountIn_);
        amountOut_ = SolvBTCRouter(router).createSubscription(poolId_, amountIn_);
        IERC20(solvBTC).transfer(msg.sender, amountOut_);
        emit Deposit(poolId_, msg.sender, amountIn_, amountOut_);
    }

}