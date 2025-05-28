// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTCYieldToken.sol";
import "../contracts/SolvBTCYieldTokenV3.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";
import "../contracts/IxSolvBTCPool.sol";
import "../contracts/XSolvBTCPool.sol";
import "../contracts/SolvBTCRouterV2.sol";
import "../contracts/SolvBTCV3_1.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCYieldTokenV3_1.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/oracle/XSolvBTCOracle.sol";

interface IProxyAdmin {
    function upgrade(ITransparentUpgradeableProxy proxy, address implementation) external;
}

interface IOpenFundMarketForAdmin {
    function updateFundraisingEndTime(bytes32 poolId_, uint64 newEndTime_) external;
}

contract xSolvBTCTest is Test {
    //use arbitrum chain
    address internal constant xSolvBTC = 0xd9D920AA40f578ab794426F5C90F6C731D159DEf;
    address internal constant solvBTC = 0x7A56E1C57C7475CCf742a1832B028F0456652F97;
    address internal constant solvBTCBera = 0xE7C253EAD50976Caf7b0C2cbca569146A7741B50;
    address internal constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address internal constant FEE_RECIPIENT = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    uint64 internal constant WITHDRAW_FEE_RATE = 100; // 1%
    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant OWNER = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal constant MINTER = 0x0679E96f5EEDa5313099f812b558714717AEC176;
    address internal constant USER_1 = 0x3D64cFEEf2B66AdD5191c387E711AF47ab01e296;
    address internal constant USER_2 = 0x291c6DFDECCbc3e15486eC859faBA8B075794d59;
    address internal constant USER_3 = 0x091D23De14E6cC4b8Bbd4eEeb17cd71A68dF8Bee;
    address internal constant solvBTCRouterV2 = 0x3d93B9e8F0886358570646dAd9421564C5fE6334;
    ProxyAdmin internal constant proxyAdmin = ProxyAdmin(0xD3e96c05F2bED82271B5C9d737C215F6BcadfF68);
    address internal constant xSolvBTCMultiAssetPool = 0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D;
    address internal constant xSolvBTCMultiAssetPoolSFT = 0x982D50f8557D57B748733a3fC3d55AeF40C46756;
    uint256 internal constant xSolvBTCMultiAssetPoolSlot =
        83660682397659272392863020907646506973985956658124321060921311208510599625298;
    address internal constant openFundMarket = 0x57bB6a8563a8e8478391C79F3F433C6BA077c567;
    bytes32 internal constant xSolvBTCBeraPoolId = 0xc63f3d6660f19445e108061adf74e0471a51a33dad30fe9b4815140168fd6136;
    address internal xSolvBTCPool;

    function setUp() public {
        //fork eth mainnet
        vm.createSelectFork(vm.envString("ETH_RPC_URL"));
        //deploy xSolvBTCPool
        xSolvBTCPool = _deployXSolvBTCPool();

        //add mint role to SolvBTC and xSolvBTC
        _addMintRoleToSolvBTCAndXSolvBTC();
        _addBurnRoleToSolvBTCAndXSolvBTC();

        //upgrade solvBTCRouterV2
        _upgradeSolvBTCRouterV2();
        _updateSolvBTCRouterV2PathAndMultiAssetPool();

        //open solvBTCBera deposit
        _openSolvBTCBeraDeposit();

        //deploy xSolvBTCOracle
        address xSolvBTCOracle = _deployXSolvBTCOracle();
        //set xSolvBTCOracle to xSolvBTC
        _setXSolvBTCOracle(xSolvBTCOracle);
    }

    function test_XSolvBTCPool_depositSolvBTCToXSolvBTC() public {
        vm.startPrank(USER_1);
        uint256 depositSolvBTCAmount = 1000 * 10 ** 18;
        uint256 expectedXSolvBTCAmount = SolvBTCYieldToken(xSolvBTC).getSharesByValue(depositSolvBTCAmount);
        deal(solvBTC, USER_1, depositSolvBTCAmount);
        uint256 totalSupplyBeforeOfSolvBTC = IERC20(solvBTC).totalSupply();
        uint256 totalSupplyBeforeOfXSolvBTC = IERC20(xSolvBTC).totalSupply();
        uint256 balanceBeforeOfUser1OfSolvBTC = IERC20(solvBTC).balanceOf(USER_1);
        uint256 balanceBeforeOfUser1OfXSolvBTC = IERC20(xSolvBTC).balanceOf(USER_1);
        IERC20(solvBTC).approve(xSolvBTCPool, depositSolvBTCAmount);
        IxSolvBTCPool(xSolvBTCPool).deposit(depositSolvBTCAmount);
        uint256 totalSupplyAfterOfSolvBTC = IERC20(solvBTC).totalSupply();
        uint256 totalSupplyAfterOfXSolvBTC = IERC20(xSolvBTC).totalSupply();
        uint256 balanceAfterOfUser1OfSolvBTC = IERC20(solvBTC).balanceOf(USER_1);
        uint256 balanceAfterOfUser1OfXSolvBTC = IERC20(xSolvBTC).balanceOf(USER_1);
        assertEq(totalSupplyAfterOfSolvBTC, totalSupplyBeforeOfSolvBTC - depositSolvBTCAmount);
        assertEq(totalSupplyAfterOfXSolvBTC, totalSupplyBeforeOfXSolvBTC + expectedXSolvBTCAmount);
        assertEq(balanceAfterOfUser1OfSolvBTC, balanceBeforeOfUser1OfSolvBTC - depositSolvBTCAmount);
        assertEq(balanceAfterOfUser1OfXSolvBTC, balanceBeforeOfUser1OfXSolvBTC + expectedXSolvBTCAmount);
        vm.stopPrank();
    }

    function test_XSolvBTCPool_withdrawSolvBTCFromXSolvBTC() public {
        vm.startPrank(USER_1);
        uint256 withdrawXSolvBTCAmount = 1000 * 10 ** 18;
        uint256 expectedWithdrawSolvBTCAmount = SolvBTCYieldToken(xSolvBTC).getValueByShares(withdrawXSolvBTCAmount);
        deal(xSolvBTC, USER_1, withdrawXSolvBTCAmount);
        uint256 balanceBeforeOfUser1OfSolvBTC = IERC20(solvBTC).balanceOf(USER_1);
        uint256 balanceBeforeOfUser1OfXSolvBTC = IERC20(xSolvBTC).balanceOf(USER_1);
        uint256 totalSupplyBeforeOfSolvBTC = IERC20(solvBTC).totalSupply();
        uint256 totalSupplyBeforeOfXSolvBTC = IERC20(xSolvBTC).totalSupply();
        uint256 fee = expectedWithdrawSolvBTCAmount * WITHDRAW_FEE_RATE / 10000;
        uint256 feeRecipientBalanceBefore = IERC20(solvBTC).balanceOf(FEE_RECIPIENT);
        IxSolvBTCPool(xSolvBTCPool).withdraw(withdrawXSolvBTCAmount);
        uint256 totalSupplyAfterOfSolvBTC = IERC20(solvBTC).totalSupply();
        uint256 totalSupplyAfterOfXSolvBTC = IERC20(xSolvBTC).totalSupply();
        uint256 balanceAfterOfUser1OfSolvBTC = IERC20(solvBTC).balanceOf(USER_1);
        uint256 balanceAfterOfUser1OfXSolvBTC = IERC20(xSolvBTC).balanceOf(USER_1);
        uint256 feeRecipientBalanceAfter = IERC20(solvBTC).balanceOf(FEE_RECIPIENT);
        assertEq(balanceAfterOfUser1OfSolvBTC, balanceBeforeOfUser1OfSolvBTC + expectedWithdrawSolvBTCAmount - fee);
        assertEq(balanceAfterOfUser1OfXSolvBTC, balanceBeforeOfUser1OfXSolvBTC - withdrawXSolvBTCAmount);
        assertEq(totalSupplyAfterOfSolvBTC, totalSupplyBeforeOfSolvBTC + expectedWithdrawSolvBTCAmount);
        assertEq(totalSupplyAfterOfXSolvBTC, totalSupplyBeforeOfXSolvBTC - withdrawXSolvBTCAmount);
        assertEq(feeRecipientBalanceAfter, feeRecipientBalanceBefore + fee);

        vm.stopPrank();
    }

    function test_SolvBTCRouterV2_depositSolvBTCToXSolvBTC() public {
        vm.startPrank(USER_1);
        uint256 depositAmount = 1000 * 10 ** 18;
        deal(solvBTC, USER_1, depositAmount);
        IERC20(solvBTC).approve(solvBTCRouterV2, depositAmount);
        SolvBTCRouterV2(solvBTCRouterV2).deposit(xSolvBTC, solvBTC, depositAmount);
        vm.stopPrank();
    }

    function test_xSolvBTCPool_setWithdrawFeeRateOnlyAdmin() public {
        vm.startPrank(ADMIN);
        uint64 expectedWithdrawFeeRate = 550;
        XSolvBTCPool(xSolvBTCPool).setWithdrawFeeRateOnlyAdmin(expectedWithdrawFeeRate);
        assertEq(XSolvBTCPool(xSolvBTCPool).withdrawFeeRate(), expectedWithdrawFeeRate);
        vm.stopPrank();
    }

    function test_xSolvBTCPool_setFeeRecipientOnlyAdmin() public {
        vm.startPrank(ADMIN);
        address expectedFeeRecipient = USER_1;
        XSolvBTCPool(xSolvBTCPool).setFeeRecipientOnlyAdmin(expectedFeeRecipient);
        assertEq(XSolvBTCPool(xSolvBTCPool).feeRecipient(), expectedFeeRecipient);
        vm.stopPrank();
    }

    function test_xSolvBTCPool_setDepositAllowedOnlyAdmin() public {
        vm.startPrank(ADMIN);
        bool expectedDepositAllowed = !XSolvBTCPool(xSolvBTCPool).depositAllowed();
        XSolvBTCPool(xSolvBTCPool).setDepositAllowedOnlyAdmin(expectedDepositAllowed);
        assertEq(XSolvBTCPool(xSolvBTCPool).depositAllowed(), expectedDepositAllowed);
        vm.stopPrank();
    }

    function test_xSolvBTCPool_RevertWhenDepositAllowedIsFalse() public {
        vm.startPrank(ADMIN);
        XSolvBTCPool(xSolvBTCPool).setDepositAllowedOnlyAdmin(false);
        vm.stopPrank();
        vm.startPrank(USER_1);
        vm.expectRevert("SolvBTCMultiAssetPool: deposit not allowed");
        IxSolvBTCPool(xSolvBTCPool).deposit(1000 * 10 ** 18);
        vm.stopPrank();
    }

    function test_xSolvBTCPool_RevertWhenSetWithdrawFeeRateByNonAdmin() public {
        vm.startPrank(USER_1);
        vm.expectRevert("only admin");
        XSolvBTCPool(xSolvBTCPool).setWithdrawFeeRateOnlyAdmin(WITHDRAW_FEE_RATE);
        vm.stopPrank();
    }

    function test_xSolvBTCPool_RevertWhenSetFeeRecipientByNonAdmin() public {
        vm.startPrank(USER_1);
        vm.expectRevert("only admin");
        XSolvBTCPool(xSolvBTCPool).setFeeRecipientOnlyAdmin(USER_1);
        vm.stopPrank();
    }

    function test_SolvBTCRouterV2_depositWBTCToSolvBTCBera() public {
        vm.startPrank(USER_1);
        uint256 depositAmount = 0.001 * 10 ** 6;
        deal(WBTC, USER_1, depositAmount);
        IERC20(WBTC).approve(solvBTCRouterV2, depositAmount);
        SolvBTCRouterV2(solvBTCRouterV2).deposit(solvBTCBera, WBTC, depositAmount);
        vm.stopPrank();
    }

    function _deployXSolvBTCPool() internal returns (address) {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        XSolvBTCPool impl = new XSolvBTCPool{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl),
            address(proxyAdmin),
            abi.encodeWithSignature(
                "initialize(address,address,address,uint64)", solvBTC, xSolvBTC, FEE_RECIPIENT, WITHDRAW_FEE_RATE
            )
        );
        vm.stopPrank();
        return address(proxy);
    }

    function _deployXSolvBTCOracle() internal returns (address) {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        XSolvBTCOracle impl = new XSolvBTCOracle{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize(uint8)", 18)
        );
        XSolvBTCOracle(address(proxy)).setXSolvBTC(xSolvBTC);
        XSolvBTCOracle(address(proxy)).setNav(1.2e18);
        vm.stopPrank();
        return address(proxy);
    }

    function _upgradeSolvBTCRouterV2() internal {
        vm.startPrank(OWNER);
        SolvBTCRouterV2 impl = new SolvBTCRouterV2();
        IProxyAdmin(address(proxyAdmin)).upgrade(ITransparentUpgradeableProxy(solvBTCRouterV2), address(impl));
        vm.stopPrank();
    }

    function _updateSolvBTCRouterV2PathAndMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        //SolvBTC -> xSolvBTC
        SolvBTCRouterV2(solvBTCRouterV2).setPoolId(
            xSolvBTC, solvBTC, SolvBTCRouterV2(solvBTCRouterV2).X_SOLV_BTC_POOL_ID()
        );
        SolvBTCRouterV2(solvBTCRouterV2).setMultiAssetPool(xSolvBTC, xSolvBTCPool);

        //disable withdraw and redeem for xSolvBTC
        SolvBTCMultiAssetPool(xSolvBTCMultiAssetPool).changeSftSlotAllowedOnlyAdmin(
            xSolvBTCMultiAssetPoolSFT, xSolvBTCMultiAssetPoolSlot, false, false
        );
        vm.stopPrank();
    }

    function _setXSolvBTCOracle(address oracle_) internal {
        vm.startPrank(OWNER);
        SolvBTCYieldToken(xSolvBTC).setOracle(oracle_);
        vm.stopPrank();
    }

    function _openSolvBTCBeraDeposit() internal {
        vm.startPrank(ADMIN);
        IOpenFundMarketForAdmin(openFundMarket).updateFundraisingEndTime(
            xSolvBTCBeraPoolId, uint64(block.timestamp + 100 days)
        );
        vm.stopPrank();
    }

    function _addMintRoleToSolvBTCAndXSolvBTC() internal {
        vm.startPrank(OWNER);
        SolvBTCV3_1(solvBTC).grantRole(SolvBTC(solvBTC).SOLVBTC_MINTER_ROLE(), xSolvBTCPool);
        SolvBTCYieldTokenV3_1(xSolvBTC).grantRole(SolvBTCYieldToken(xSolvBTC).SOLVBTC_MINTER_ROLE(), xSolvBTCPool);
        vm.stopPrank();
    }

    function _addBurnRoleToSolvBTCAndXSolvBTC() internal {
        vm.startPrank(OWNER);
        SolvBTCV3_1(solvBTC).grantRole(SolvBTC(solvBTC).SOLVBTC_POOL_BURNER_ROLE(), xSolvBTCPool);
        SolvBTCYieldTokenV3_1(xSolvBTC).grantRole(SolvBTCYieldToken(xSolvBTC).SOLVBTC_POOL_BURNER_ROLE(), xSolvBTCPool);
        vm.stopPrank();
    }
}
