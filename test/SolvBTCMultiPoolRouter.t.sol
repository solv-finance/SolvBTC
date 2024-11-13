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
import "../contracts/SolvBTCMultiPoolRouter.sol";

contract SolvBTCMultiPoolRouterTest is Test {

    // fork ethereum mainnet for test
    address internal constant MARKET_ADDRESS = 0x57bB6a8563a8e8478391C79F3F433C6BA077c567;
    address internal constant SOLVBTC_MULTI_ASSET_POOL_ADDRESS = 0x1d5262919C4AAb745A8C9dD56B80DB9FeaEf86BA;
    address internal constant SOLVBTC_YIELD_TOKEN_MULTI_ASSET_POOL_ADDRESS = 0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D;

    bytes32 internal constant SOLVBTC_WBTC_POOL_ID = 0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307;
    bytes32 internal constant SOLVBTC_BBN_POOL_ID = 0xefcca1eb946cdc7b56509489a56b45b75aff74b8bb84dad5b893012157e0df93;

    address internal constant WBTC_ADDRESS = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant SOLVBTC_BBN_ADDRESS = 0xd9D920AA40f578ab794426F5C90F6C731D159DEf;

    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;

    ProxyAdmin internal proxyAdmin;
    SolvBTCMultiPoolRouter internal solvBTCMultiPoolRouter;

    address internal user = makeAddr("USER");

    function setUp() public {
        vm.startPrank(ADMIN);
        proxyAdmin = new ProxyAdmin(ADMIN);
        SolvBTCMultiPoolRouter impl = new SolvBTCMultiPoolRouter();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl), address(proxyAdmin), 
            abi.encodeWithSignature(
                "initialize(address,address,address,address)",
                ADMIN, MARKET_ADDRESS, SOLVBTC_MULTI_ASSET_POOL_ADDRESS, SOLVBTC_YIELD_TOKEN_MULTI_ASSET_POOL_ADDRESS
            )
        );
        solvBTCMultiPoolRouter = SolvBTCMultiPoolRouter(address(proxy));
        solvBTCMultiPoolRouter.setSolvBTCPoolIdByCurrency(WBTC_ADDRESS, SOLVBTC_WBTC_POOL_ID);
        vm.stopPrank();
    }

    function test_Subscribe() public {
        deal(WBTC_ADDRESS, user, 10e8);

        uint256 wbtcBalanceBefore = IERC20(WBTC_ADDRESS).balanceOf(user);
        uint256 solvBTCBBNBalanceBefore = IERC20(SOLVBTC_BBN_ADDRESS).balanceOf(user);
        
        vm.startPrank(user);
        IERC20(WBTC_ADDRESS).approve(address(solvBTCMultiPoolRouter), 10e8);
        solvBTCMultiPoolRouter.createSubscription(SOLVBTC_BBN_POOL_ID, WBTC_ADDRESS, 10e8);
        vm.stopPrank();

        uint256 wbtcBalanceAfter = IERC20(WBTC_ADDRESS).balanceOf(user);
        uint256 solvBTCBBNBalanceAfter = IERC20(SOLVBTC_BBN_ADDRESS).balanceOf(user);

        console.log(wbtcBalanceBefore, wbtcBalanceAfter);
        console.log(solvBTCBBNBalanceBefore, solvBTCBBNBalanceAfter);
    }
}
