// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../contracts/FeeManager.sol";
import "../contracts/SolvBTCYieldToken.sol";
import "../contracts/SolvBTCRouter.sol";
import "../contracts/SolvBTCRouterV2.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";
import "../contracts/XSolvBTCPool.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

interface IProxyAdmin {
    function upgrade(ITransparentUpgradeableProxy proxy, address implementation) external;
}

// fork bnb chain mainnet at block 61300000
contract FeeManagerTest is Test {

    SolvBTCRouter internal solvbtcRouter = SolvBTCRouter(0x5c1215712F174dF2Cbc653eDce8B53FA4CAF2201);
    SolvBTCRouter internal lstRouter = SolvBTCRouter(0x8EC6Ef69a423045cEa97d2Bd0D768D042A130aA7);
    SolvBTCRouterV2 internal solvbtcRouterV2 = SolvBTCRouterV2(0x67035877F5c12202c387d1698274C2aBF28F3678);
    SolvBTCMultiAssetPool internal solvbtcPool = SolvBTCMultiAssetPool(0x1FF72318deeD339e724e3c8deBCD528dC013D845);
    SolvBTCMultiAssetPool internal lstPool = SolvBTCMultiAssetPool(0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A);
    XSolvBTCPool internal xsolvbtcPool = XSolvBTCPool(0xF50860533D209E44dbe02F58B77EA85a8bfC28a3);
    FeeManager internal feeManager;

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0x336eaa590faD054B70E845ff9f4052c2B8DF96F8);

    address internal constant BTCB = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c;
    address internal constant SOLVBTC = 0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7;
    address internal constant XSOLVBTC = 0x1346b618dC92810EC74163e4c27004c921D446a5;
    address internal constant SOLVBTC_BERA = 0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B;
    address internal constant BTCPLUS = 0x4Ca70811E831db42072CBa1f0d03496EF126fAad;
    address internal constant SOLVBTC_BNB = 0x6c948A4C31D013515d871930Fe3807276102F25d;

    bytes32 internal constant SOLVBTC_POOL_ID = 0xafb1107b43875eb79f72e3e896933d4f96707451c3d5c32741e8e05410b321d8;
    bytes32 internal constant SOLVBTC_BERA_POOL_ID = 0x0b2bb30466fb1d5b0c664f9a6e4e1a90d5c8bc5abaecd823563641d6fc5ae57a;
    bytes32 internal constant BTCPLUS_POOL_ID = 0xd3b1d3c5c203cd23f4fc80443559069b1e313302a10a86d774345dc4ad81b0f6;
    bytes32 internal constant SOLVBTC_BNB_POOL_ID = 0x02228958e4f53e94e09cc0afd49939bf93af0b991889fa5fe761672c0e9c3021;

    address internal constant OWNER = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;

    address internal randomContract = makeAddr("random contract");
    address internal feeReceiver = makeAddr("fee receiver");
    address internal user_1 = makeAddr("user 1");

    event SetDepositFee(address indexed targetToken, address indexed currency, uint64 feeRate, address feeReceiver);
    event CollectDepositFee(address indexed payer, address indexed currency, address indexed feeReceiver, uint256 feeAmount);

    function setUp() public {
        //fork eth mainnet
        vm.createSelectFork(vm.envString("BSC_RPC_URL"), 61300000);

        _deployFeeManager();
        _upgradeSolvBTCRouter();
        _upgradeLstRouter();
        _upgradeSolvBTCRouterV2();
        _upgradeSolvBTCMultiAssetPool();
        _upgradeLstMultiAssetPool();
        _upgradeXSolvBTCPool();
    }

    function test_StatusAfterUpgrade() public {
        assertEq(feeManager.owner(), OWNER);
        assertEq(solvbtcRouter.feeManager(), address(feeManager));
        assertEq(solvbtcRouterV2.feeManager(), address(feeManager));
        assertEq(solvbtcPool.isCallerAllowed(address(solvbtcRouter)), true);
        assertEq(solvbtcPool.isCallerAllowed(address(solvbtcRouterV2)), true);
        assertEq(solvbtcPool.isCallerAllowed(address(lstRouter)), false);
        assertEq(lstPool.isCallerAllowed(address(lstRouter)), true);
        assertEq(lstPool.isCallerAllowed(address(solvbtcRouterV2)), true);
        assertEq(lstPool.isCallerAllowed(address(solvbtcRouter)), false);
        assertEq(xsolvbtcPool.isCallerAllowed(address(solvbtcRouterV2)), true);
        assertEq(xsolvbtcPool.isCallerAllowed(address(solvbtcRouter)), false);
        assertEq(xsolvbtcPool.isCallerAllowed(address(lstRouter)), false);
    }

    function test_SetDepositFee() public {
        vm.startPrank(OWNER);
        vm.expectEmit();
        emit SetDepositFee(SOLVBTC, BTCB, 0.01e8, feeReceiver);
        feeManager.setDepositFee(SOLVBTC, BTCB, 0.01e8, feeReceiver);
        (uint256 feeAmount_, address feeReceiver_) = feeManager.getDepositFee(SOLVBTC, BTCB, 1e8);
        assertEq(feeAmount_, 0.01e8);
        assertEq(feeReceiver_, feeReceiver);

        feeManager.setDepositFee(SOLVBTC, BTCB, 0, address(0));
        (feeAmount_, feeReceiver_) = feeManager.getDepositFee(SOLVBTC, BTCB, 1e8);
        assertEq(feeAmount_, 0);
        assertEq(feeReceiver_, address(0));
        vm.stopPrank();
    }

    function test_RevertWhenSetDepositFeeByNonOwner() public {
        vm.startPrank(randomContract);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", randomContract));
        feeManager.setDepositFee(SOLVBTC, BTCB, 0.01e8, feeReceiver);
        vm.stopPrank();
    }

    function test_RevertWhenSetDepositFeeWithZeroAddress() public {
        vm.startPrank(OWNER);
        vm.expectRevert("FeeManager: targetToken is zero address");
        feeManager.setDepositFee(address(0), BTCB, 0.01e8, feeReceiver);
        vm.expectRevert("FeeManager: currency is zero address");
        feeManager.setDepositFee(SOLVBTC, address(0), 0.01e8, feeReceiver);
        vm.stopPrank();
    }

    function test_RevertWhenSetDepositFeeWithInvalidFeeParams() public {
        vm.startPrank(OWNER);
        vm.expectRevert("FeeManager: feeRate exceeds 100%");
        feeManager.setDepositFee(SOLVBTC, BTCB, 1.01e8, feeReceiver);
        vm.expectRevert("FeeManager: feeReceiver is zero address");
        feeManager.setDepositFee(SOLVBTC, BTCB, 0.1e8, address(0));
        vm.stopPrank();
    }

    function test_SubscribeSolvbtcWithRouter() public {
        vm.startPrank(OWNER);
        feeManager.setDepositFee(SOLVBTC, BTCB, 0.01e8, feeReceiver);
        vm.stopPrank();

        deal(BTCB, user_1, 100 ether);
        uint256 userBtcbBalanceBefore = IERC20(BTCB).balanceOf(user_1);
        uint256 userSolvbtcBalanceBefore = IERC20(SOLVBTC).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceBefore = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverSolvbtcBalanceBefore = IERC20(SOLVBTC).balanceOf(feeReceiver);

        vm.startPrank(user_1);
        IERC20(BTCB).approve(address(solvbtcRouter), 1 ether);
        vm.expectEmit();
        emit CollectDepositFee(user_1, BTCB, feeReceiver, 0.01 ether);
        solvbtcRouter.createSubscription(SOLVBTC_POOL_ID, 1 ether);
        vm.stopPrank();

        uint256 userBtcbBalanceAfter = IERC20(BTCB).balanceOf(user_1);
        uint256 userSolvbtcBalanceAfter = IERC20(SOLVBTC).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceAfter = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverSolvbtcBalanceAfter = IERC20(SOLVBTC).balanceOf(feeReceiver);

        assertEq(userBtcbBalanceBefore - userBtcbBalanceAfter, 1 ether);
        assertEq(userSolvbtcBalanceAfter - userSolvbtcBalanceBefore, 0.99 ether);
        assertEq(feeReceiverBtcbBalanceAfter - feeReceiverBtcbBalanceBefore, 0.01 ether);
        assertEq(feeReceiverSolvbtcBalanceAfter, feeReceiverSolvbtcBalanceBefore);
    }

    function test_SubscribeLstWithRouter() public {
        vm.startPrank(OWNER);
        feeManager.setDepositFee(BTCPLUS, SOLVBTC, 0.015e8, feeReceiver);
        vm.stopPrank();

        deal(SOLVBTC, user_1, 100 ether);
        uint256 userSolvbtcBalanceBefore = IERC20(SOLVBTC).balanceOf(user_1);
        uint256 userBtcplusBalanceBefore = IERC20(BTCPLUS).balanceOf(user_1);
        uint256 feeReceiverSolvbtcBalanceBefore = IERC20(SOLVBTC).balanceOf(feeReceiver);
        uint256 feeReceiverBtcplusBalanceBefore = IERC20(BTCPLUS).balanceOf(feeReceiver);

        vm.startPrank(user_1);
        IERC20(SOLVBTC).approve(address(lstRouter), 1 ether);
        vm.expectEmit();
        emit CollectDepositFee(user_1, SOLVBTC, feeReceiver, 0.015 ether);
        lstRouter.createSubscription(BTCPLUS_POOL_ID, 1 ether);
        vm.stopPrank();

        uint256 expectBtcplusAmount = SolvBTCYieldToken(BTCPLUS).getSharesByValue(0.985 ether);
        uint256 userSolvbtcBalanceAfter = IERC20(SOLVBTC).balanceOf(user_1);
        uint256 userBtcplusBalanceAfter = IERC20(BTCPLUS).balanceOf(user_1);
        uint256 feeReceiverSolvbtcBalanceAfter = IERC20(SOLVBTC).balanceOf(feeReceiver);
        uint256 feeReceiverBtcplusBalanceAfter = IERC20(BTCPLUS).balanceOf(feeReceiver);

        assertEq(userSolvbtcBalanceBefore - userSolvbtcBalanceAfter, 1 ether);
        assertEq(userBtcplusBalanceAfter - userBtcplusBalanceBefore, expectBtcplusAmount);
        assertEq(feeReceiverSolvbtcBalanceAfter - feeReceiverSolvbtcBalanceBefore, 0.015 ether);
        assertEq(feeReceiverBtcplusBalanceAfter, feeReceiverBtcplusBalanceBefore);
    }

    function test_SubscribeSolvbtcWithRouterV2() public {
        vm.startPrank(OWNER);
        feeManager.setDepositFee(SOLVBTC, BTCB, 0.01e8, feeReceiver);
        vm.stopPrank();

        deal(BTCB, user_1, 100 ether);
        uint256 userBtcbBalanceBefore = IERC20(BTCB).balanceOf(user_1);
        uint256 userSolvbtcBalanceBefore = IERC20(SOLVBTC).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceBefore = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverSolvbtcBalanceBefore = IERC20(SOLVBTC).balanceOf(feeReceiver);

        vm.startPrank(user_1);
        IERC20(BTCB).approve(address(solvbtcRouterV2), 1 ether);
        vm.expectEmit();
        emit CollectDepositFee(user_1, BTCB, feeReceiver, 0.01 ether);
        solvbtcRouterV2.deposit(SOLVBTC, BTCB, 1 ether, 0.9 ether, uint64(block.timestamp + 300));
        vm.stopPrank();

        uint256 userBtcbBalanceAfter = IERC20(BTCB).balanceOf(user_1);
        uint256 userSolvbtcBalanceAfter = IERC20(SOLVBTC).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceAfter = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverSolvbtcBalanceAfter = IERC20(SOLVBTC).balanceOf(feeReceiver);

        assertEq(userBtcbBalanceBefore - userBtcbBalanceAfter, 1 ether);
        assertEq(userSolvbtcBalanceAfter - userSolvbtcBalanceBefore, 0.99 ether);
        assertEq(feeReceiverBtcbBalanceAfter - feeReceiverBtcbBalanceBefore, 0.01 ether);
        assertEq(feeReceiverSolvbtcBalanceAfter, feeReceiverSolvbtcBalanceBefore);
    }

    function test_SubscribeLstWithRouterV2() public {
        vm.startPrank(OWNER);
        feeManager.setDepositFee(BTCPLUS, BTCB, 0.02e8, feeReceiver);
        vm.stopPrank();

        deal(BTCB, user_1, 100 ether);
        uint256 userBtcbBalanceBefore = IERC20(BTCB).balanceOf(user_1);
        uint256 userBtcplusBalanceBefore = IERC20(BTCPLUS).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceBefore = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverBtcplusBalanceBefore = IERC20(BTCPLUS).balanceOf(feeReceiver);

        vm.startPrank(user_1);
        IERC20(BTCB).approve(address(solvbtcRouterV2), 1 ether);
        vm.expectEmit();
        emit CollectDepositFee(user_1, BTCB, feeReceiver, 0.02 ether);
        solvbtcRouterV2.deposit(BTCPLUS, BTCB, 1 ether, 0.9 ether, uint64(block.timestamp + 300));
        vm.stopPrank();

        uint256 expectBtcplusAmount = SolvBTCYieldToken(BTCPLUS).getSharesByValue(0.98 ether);
        uint256 userBtcbBalanceAfter = IERC20(BTCB).balanceOf(user_1);
        uint256 userBtcplusBalanceAfter = IERC20(BTCPLUS).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceAfter = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverBtcplusBalanceAfter = IERC20(BTCPLUS).balanceOf(feeReceiver);

        assertEq(userBtcbBalanceBefore - userBtcbBalanceAfter, 1 ether);
        assertEq(userBtcplusBalanceAfter - userBtcplusBalanceBefore, expectBtcplusAmount);
        assertEq(feeReceiverBtcbBalanceAfter - feeReceiverBtcbBalanceBefore, 0.02 ether);
        assertEq(feeReceiverBtcplusBalanceAfter, feeReceiverBtcplusBalanceBefore);
    }

    function test_SubscribeXSolvbtcWithRouterV2() public {
        vm.startPrank(OWNER);
        feeManager.setDepositFee(XSOLVBTC, BTCB, 0.02e8, feeReceiver);
        vm.stopPrank();

        deal(BTCB, user_1, 100 ether);
        uint256 userBtcbBalanceBefore = IERC20(BTCB).balanceOf(user_1);
        uint256 userXSolvbtcBalanceBefore = IERC20(XSOLVBTC).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceBefore = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverXSolvbtcBalanceBefore = IERC20(XSOLVBTC).balanceOf(feeReceiver);

        vm.startPrank(user_1);
        IERC20(BTCB).approve(address(solvbtcRouterV2), 1 ether);
        vm.expectEmit();
        emit CollectDepositFee(user_1, BTCB, feeReceiver, 0.02 ether);
        solvbtcRouterV2.deposit(XSOLVBTC, BTCB, 1 ether, 0.9 ether, uint64(block.timestamp + 300));
        vm.stopPrank();

        uint256 expectXSolvbtcAmount = SolvBTCYieldToken(XSOLVBTC).getSharesByValue(0.98 ether);
        uint256 userBtcbBalanceAfter = IERC20(BTCB).balanceOf(user_1);
        uint256 userXSolvbtcBalanceAfter = IERC20(XSOLVBTC).balanceOf(user_1);
        uint256 feeReceiverBtcbBalanceAfter = IERC20(BTCB).balanceOf(feeReceiver);
        uint256 feeReceiverXSolvbtcBalanceAfter = IERC20(XSOLVBTC).balanceOf(feeReceiver);

        assertEq(userBtcbBalanceBefore - userBtcbBalanceAfter, 1 ether);
        assertEq(userXSolvbtcBalanceAfter - userXSolvbtcBalanceBefore, expectXSolvbtcAmount);
        assertEq(feeReceiverBtcbBalanceAfter - feeReceiverBtcbBalanceBefore, 0.02 ether);
        assertEq(feeReceiverXSolvbtcBalanceAfter, feeReceiverXSolvbtcBalanceBefore);
    }

    function test_RevertWhenCallSolvbtcPoolByNonAllowedCaller() public {
        vm.startPrank(randomContract);
        vm.expectRevert("CallerControl: caller not allowed");
        solvbtcPool.deposit(makeAddr("sft"), 1, 1 ether);
        vm.expectRevert("CallerControl: caller not allowed");
        solvbtcPool.withdraw(makeAddr("sft"), 999, 1, 1 ether);
        vm.stopPrank();

        address[] memory callers = new address[](1);
        callers[0] = address(solvbtcRouter);
        vm.startPrank(ADMIN);
        solvbtcPool.setCallerAllowedOnlyAdmin(callers, false);
        vm.stopPrank();

        vm.startPrank(address(solvbtcRouter));
        vm.expectRevert("CallerControl: caller not allowed");
        solvbtcPool.deposit(makeAddr("sft"), 1, 1 ether);
        vm.expectRevert("CallerControl: caller not allowed");
        solvbtcPool.withdraw(makeAddr("sft"), 999, 1, 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhenCallLstPoolByNonAllowedCaller() public {
        vm.startPrank(randomContract);
        vm.expectRevert("CallerControl: caller not allowed");
        lstPool.deposit(makeAddr("sft"), 1, 1 ether);
        vm.expectRevert("CallerControl: caller not allowed");
        lstPool.withdraw(makeAddr("sft"), 999, 1, 1 ether);
        vm.stopPrank();

        address[] memory callers = new address[](1);
        callers[0] = address(solvbtcRouter);
        vm.startPrank(ADMIN);
        lstPool.setCallerAllowedOnlyAdmin(callers, false);
        vm.stopPrank();

        vm.startPrank(address(solvbtcRouter));
        vm.expectRevert("CallerControl: caller not allowed");
        lstPool.deposit(makeAddr("sft"), 1, 1 ether);
        vm.expectRevert("CallerControl: caller not allowed");
        lstPool.withdraw(makeAddr("sft"), 999, 1, 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhenCallXSolvbtcPoolByNonAllowedCaller() public {
        vm.startPrank(randomContract);
        vm.expectRevert("CallerControl: caller not allowed");
        xsolvbtcPool.deposit(1 ether);
        vm.expectRevert("CallerControl: caller not allowed");
        xsolvbtcPool.withdraw(1 ether);
        vm.stopPrank();

        address[] memory callers = new address[](1);
        callers[0] = address(solvbtcRouter);
        vm.startPrank(ADMIN);
        xsolvbtcPool.setCallerAllowedOnlyAdmin(callers, false);
        vm.stopPrank();

        vm.startPrank(address(solvbtcRouter));
        vm.expectRevert("CallerControl: caller not allowed");
        xsolvbtcPool.deposit(1 ether);
        vm.expectRevert("CallerControl: caller not allowed");
        xsolvbtcPool.withdraw(1 ether);
        vm.stopPrank();
    }


    /** Internal functions */

    function _deployFeeManager() internal {
        vm.startPrank(OWNER);
        FeeManager impl = new FeeManager();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize()")
        );
        feeManager = FeeManager(address(proxy));
        vm.stopPrank();
    }

    function _upgradeSolvBTCRouter() internal {
        vm.startPrank(OWNER);
        SolvBTCRouter impl = new SolvBTCRouter();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(address(solvbtcRouter)), address(impl));
        vm.stopPrank();

        vm.startPrank(ADMIN);
        solvbtcRouter.setFeeManager(address(feeManager));
        vm.stopPrank();
    }

    function _upgradeLstRouter() internal {
        vm.startPrank(OWNER);
        SolvBTCRouter impl = new SolvBTCRouter();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(address(lstRouter)), address(impl));
        vm.stopPrank();

        vm.startPrank(ADMIN);
        lstRouter.setFeeManager(address(feeManager));
        vm.stopPrank();
    }

    function _upgradeSolvBTCRouterV2() internal {
        vm.startPrank(OWNER);
        SolvBTCRouterV2 impl = new SolvBTCRouterV2();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(address(solvbtcRouterV2)), address(impl));
        vm.stopPrank();

        vm.startPrank(ADMIN);
        solvbtcRouterV2.setFeeManager(address(feeManager));
        vm.stopPrank();
    }

    function _upgradeSolvBTCMultiAssetPool() internal {
        vm.startPrank(OWNER);
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(address(solvbtcPool)), address(impl));
        vm.stopPrank();

        address[] memory callers = new address[](2);
        callers[0] = address(solvbtcRouter);
        callers[1] = address(solvbtcRouterV2);
        vm.startPrank(ADMIN);
        solvbtcPool.setCallerAllowedOnlyAdmin(callers, true);
        vm.stopPrank();
    }

    function _upgradeLstMultiAssetPool() internal {
        vm.startPrank(OWNER);
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(address(lstPool)), address(impl));
        vm.stopPrank();

        address[] memory callers = new address[](2);
        callers[0] = address(lstRouter);
        callers[1] = address(solvbtcRouterV2);
        vm.startPrank(ADMIN);
        lstPool.setCallerAllowedOnlyAdmin(callers, true);
        vm.stopPrank();
    }

    function _upgradeXSolvBTCPool() internal {
        vm.startPrank(OWNER);
        XSolvBTCPool impl = new XSolvBTCPool();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(address(xsolvbtcPool)), address(impl));
        vm.stopPrank();

        address[] memory callers = new address[](1);
        callers[0] = address(solvbtcRouterV2);
        vm.startPrank(ADMIN);
        xsolvbtcPool.setCallerAllowedOnlyAdmin(callers, true);
        vm.stopPrank();
    }
}
