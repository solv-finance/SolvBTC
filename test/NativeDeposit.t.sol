// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/NativeDeposit.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";
import "../contracts/SolvBTCRouter.sol";

contract NativeDepositTest is Test {

    address internal constant WRAP_TOKEN_ADDRESS = 0x542fDA317318eBF1d3DEAf76E0b632741A7e677d;
    address internal constant SOLVBTC_ADDRESS = 0x541FD749419CA806a8bc7da8ac23D346f2dF8B77;
    address internal constant SOLVBTC_ROUTER_ADDRESS = 0xeFD6F956d68ce2A2338D3c0b12cC51Fd0504D233;

    NativeDeposit internal nativeDeposit;

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0x02a90b43A9179e51eEC59415395437fa8E05dcd9);
    
    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;

    address internal USER = makeAddr("user");

    function setUp() public {
        _deployNativeDeposit();
        vm.deal(USER, 10 ether);
    }

    function test_NativeDepositStatus() public {
        assertEq(nativeDeposit.wrapToken(), WRAP_TOKEN_ADDRESS);
        assertEq(nativeDeposit.solvBTC(), SOLVBTC_ADDRESS);
        assertEq(nativeDeposit.router(), SOLVBTC_ROUTER_ADDRESS);
    }

    function test_NativeDeposit() public {
        uint256 rbtcBalanceBefore = USER.balance;
        uint256 solvBTCBalanceBefore = IERC20(SOLVBTC_ADDRESS).balanceOf(USER);
        uint256 amountOut = nativeDeposit.deposit(0, 1 ether);
        uint256 rbtcBalanceAfter = USER.balance;
        uint256 solvBTCBalanceAfter = IERC20(SOLVBTC_ADDRESS).balanceOf(USER);
        assertEq(amountOut, 1 ether);
        assertEq(rbtcBalanceBefore - rbtcBalanceAfter, 1 ether);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, 1 ether);
    }

    function _deployNativeDeposit() internal {
        vm.startPrank(ADMIN);
        NativeDeposit impl = new NativeDeposit();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl), address(proxyAdmin), 
            abi.encodeWithSignature(
                "initialize(address,address,address)", 
                WRAP_TOKEN_ADDRESS, SOLVBTC_ADDRESS, SOLVBTC_ROUTER_ADDRESS
            )
        );
        nativeDeposit = NativeDeposit(address(proxy));
        vm.stopPrank();
    }

}
