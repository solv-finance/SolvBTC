// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrappedTokenFactory.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";
import "../contracts/SolvBTCRouter.sol";
import "../contracts/SolvBTCRouterV2.sol";

contract SolvBTCRouterV2Test is Test {

    // fork ethereum mainnet for test
    address internal constant MARKET_ADDRESS = 0x57bB6a8563a8e8478391C79F3F433C6BA077c567;
    address internal constant SOLVBTC_MULTI_ASSET_POOL_ADDRESS = 0x1d5262919C4AAb745A8C9dD56B80DB9FeaEf86BA;
    address internal constant SOLVBTC_YIELD_TOKEN_MULTI_ASSET_POOL_ADDRESS = 0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D;

    bytes32 internal constant SOLVBTC_WBTC_POOL_ID = 0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307;
    bytes32 internal constant SOLVBTC_BBN_POOL_ID = 0xefcca1eb946cdc7b56509489a56b45b75aff74b8bb84dad5b893012157e0df93;

    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant SOLVBTC = 0x7A56E1C57C7475CCf742a1832B028F0456652F97;
    address internal constant SOLVBTCBBN = 0xd9D920AA40f578ab794426F5C90F6C731D159DEf;

    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;

    ProxyAdmin internal proxyAdmin;
    SolvBTCRouterV2 internal solvBTCRouterV2;

    address internal user = makeAddr("USER");

    function setUp() public {
        vm.startPrank(ADMIN);
        proxyAdmin = new ProxyAdmin(ADMIN);
        SolvBTCRouterV2 impl = new SolvBTCRouterV2();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl), address(proxyAdmin), 
            abi.encodeWithSignature("initialize(address)", ADMIN)
        );
        solvBTCRouterV2 = SolvBTCRouterV2(address(proxy));

        solvBTCRouterV2.setOpenFundMarket(MARKET_ADDRESS);
        
        solvBTCRouterV2.setPoolId(SOLVBTC, WBTC, SOLVBTC_WBTC_POOL_ID);
        solvBTCRouterV2.setPoolId(SOLVBTCBBN, SOLVBTC, SOLVBTC_BBN_POOL_ID);
        
        solvBTCRouterV2.setPath(WBTC, SOLVBTC, new address[](0));
        address[] memory path = new address[](1);
        path[0] = SOLVBTC;
        solvBTCRouterV2.setPath(WBTC, SOLVBTCBBN, path);

        solvBTCRouterV2.setMultiAssetPool(SOLVBTC, SOLVBTC_MULTI_ASSET_POOL_ADDRESS);
        solvBTCRouterV2.setMultiAssetPool(SOLVBTCBBN, SOLVBTC_YIELD_TOKEN_MULTI_ASSET_POOL_ADDRESS);
        vm.stopPrank();
    }

    function test_Deposit_WBTC_for_SOLVBTC() public {
        deal(WBTC, user, 10e8);

        uint256 wbtcBalanceBefore = IERC20(WBTC).balanceOf(user);
        uint256 solvBTCBalanceBefore = IERC20(SOLVBTC).balanceOf(user);
        
        vm.startPrank(user);
        IERC20(WBTC).approve(address(solvBTCRouterV2), 10e8);
        solvBTCRouterV2.deposit(SOLVBTC, WBTC, 10e8);
        vm.stopPrank();

        uint256 wbtcBalanceAfter = IERC20(WBTC).balanceOf(user);
        uint256 solvBTCBalanceAfter = IERC20(SOLVBTC).balanceOf(user);

        assertEq(wbtcBalanceBefore - wbtcBalanceAfter, 10e8);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, 10e18);
    }

    function test_Deposit_WBTC_for_SOLVBTCBBN() public {
        deal(WBTC, user, 10e8);

        uint256 wbtcBalanceBefore = IERC20(WBTC).balanceOf(user);
        uint256 solvBTCBBNBalanceBefore = IERC20(SOLVBTCBBN).balanceOf(user);
        
        vm.startPrank(user);
        IERC20(WBTC).approve(address(solvBTCRouterV2), 10e8);
        solvBTCRouterV2.deposit(SOLVBTCBBN, WBTC, 10e8);
        vm.stopPrank();

        uint256 wbtcBalanceAfter = IERC20(WBTC).balanceOf(user);
        uint256 solvBTCBBNBalanceAfter = IERC20(SOLVBTCBBN).balanceOf(user);

        assertEq(wbtcBalanceBefore - wbtcBalanceAfter, 10e8);
        assertEq(solvBTCBBNBalanceAfter - solvBTCBBNBalanceBefore, 10e18);
    }

    function test_WithdrawRequest() public {
        deal(SOLVBTCBBN, user, 10e18);
        uint256 solvBTCBBNBalanceBefore = IERC20(SOLVBTCBBN).balanceOf(user);

        vm.startPrank(user);
        IERC20(SOLVBTCBBN).approve(address(solvBTCRouterV2), 10e18);
        (address redemption, uint256 redemptionId) = solvBTCRouterV2.withdrawRequest(SOLVBTCBBN, SOLVBTC, 10e18);
        vm.stopPrank();

        uint256 solvBTCBBNBalanceAfter = IERC20(SOLVBTCBBN).balanceOf(user);
        assertEq(solvBTCBBNBalanceBefore - solvBTCBBNBalanceAfter, 10e18);
        assertEq(IERC3525(redemption).balanceOf(user), 1);
        assertEq(IERC3525(redemption).balanceOf(redemptionId), 10e18);
        assertEq(IERC3525(redemption).ownerOf(redemptionId), user);
    }

    function test_CancelWithdrawRequest() public {
        deal(SOLVBTCBBN, user, 10e18);

        vm.startPrank(user);
        IERC20(SOLVBTCBBN).approve(address(solvBTCRouterV2), 10e18);
        (address redemption, uint256 redemptionId) = solvBTCRouterV2.withdrawRequest(SOLVBTCBBN, SOLVBTC, 10e18);

        uint256 solvBTCBBNBalanceBefore = IERC20(SOLVBTCBBN).balanceOf(user);
        IERC3525(redemption).approve(address(solvBTCRouterV2), redemptionId);
        solvBTCRouterV2.cancelWithdrawRequest(SOLVBTCBBN, redemption, redemptionId);
        uint256 solvBTCBBNBalanceAfter = IERC20(SOLVBTCBBN).balanceOf(user);
        vm.stopPrank();

        assertEq(solvBTCBBNBalanceAfter - solvBTCBBNBalanceBefore, 10e18);
        assertEq(IERC3525(redemption).balanceOf(user), 0);
        vm.expectRevert("ERC3525: invalid token ID");
        IERC3525(redemption).ownerOf(redemptionId);
    }
}
