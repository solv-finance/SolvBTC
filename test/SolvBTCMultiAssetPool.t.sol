// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrapRouter.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";

contract SolvBTCMultiAssetPoolTest is Test {
    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "Solv BTC";

    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant GOVERNOR = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant USER = 0xbDfA4f4492dD7b7Cf211209C4791AF8d52BF5c50;

    address internal constant SOLVBTC_SFT = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    uint256 internal constant SOLVBTC_SLOT =
        39475026322910990648776764986670533412889479187054865546374468496663502783148;
    uint256 internal constant SOLVBTC_HOLDING_VALUE_SFT_ID = 72;

    address internal constant SOLVBTC_HOLDER_1 = 0xaCacB98d4419e37AeC57b738F7B2f6982d0075BB;
    address internal constant SOLVBTC_HOLDER_2 = 0x51DE77F8764e15ce4f28517169588762d6C58aF5;

    uint256 internal constant SOLVBTC_SFT_ID_1 = 66;
    address internal constant SOLVBTC_SFT_HOLDER_1 = 0x07a1f6fc89223c5ebD4e4ddaE89Ac97629856A0f;
    uint256 internal constant SOLVBTC_SFT_ID_2 = 77;
    address internal constant SOLVBTC_SFT_HOLDER_2 = 0xFc220fB83314B4b1E00421777CB579a68f17c439;

    address internal constant FUND_SFT = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    uint256 internal constant GMXBTCA_SLOT =
        70120449060830493694329237233476283664004495384113064083934107225342856266913;
    uint256 internal constant GMXBTCB_SLOT =
        18834720600760682316079182603327587109774167238702271733823387280510631407444;
    uint256 internal GMXBTCA_HOLDING_VALUE_SFT_ID;
    uint256 internal GMXBTCB_HOLDING_VALUE_SFT_ID;

    uint256 internal constant GMXBTCA_SFT_ID_1 = 7168;
    address internal constant GMXBTCA_SFT_HOLDER_1 = 0x97B5a7a1603829492dE6E8593eD4f956F4Ee980F;
    uint256 internal constant GMXBTCA_SFT_ID_2 = 7156;
    address internal constant GMXBTCA_SFT_HOLDER_2 = 0x09d06B0253766e731E1919602d43d3A70cfde3B9;

    uint256 internal constant GMXBTCB_SFT_ID_1 = 3305;
    address internal constant GMXBTCB_SFT_HOLDER_1 = 0xa294eD3233D0b45feDaAae558B00d748c668536A;
    uint256 internal constant GMXBTCB_SFT_ID_2 = 2373;
    address internal constant GMXBTCB_SFT_HOLDER_2 = 0xEe73C999A277173b01Fc215D02F13d0759D13d01;

    uint256 internal constant SOLVBTCENA_SLOT =
        73370673862338774703804051393194258049657950181644297527289682663167654669645;

    SftWrappedTokenFactory internal factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);
    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTC internal gmxBTC;
    SolvBTCMultiAssetPool internal solvBTCMultiAssetPool;
    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    function setUp() public virtual {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        _setupSolvBTC();
        _deployGmxBTC();
    }

    function test_InitialStatus() public {
        assertEq(solvBTCMultiAssetPool.admin(), ADMIN);
        assertEq(solvBTCMultiAssetPool.pendingAdmin(), address(0));
        assertFalse(solvBTCMultiAssetPool.isSftSlotDepositAllowed(SOLVBTC_SFT, SOLVBTC_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, GMXBTCA_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, GMXBTCB_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(SOLVBTC_SFT, SOLVBTC_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, GMXBTCA_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, GMXBTCB_SLOT));
    }

    /**
     * Tests for add/remove sft slots
     */
    function test_AddSftSlot() public {
        _addDefaultSftSlots();
        assertTrue(solvBTCMultiAssetPool.isSftSlotDepositAllowed(SOLVBTC_SFT, SOLVBTC_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, GMXBTCA_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, GMXBTCB_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, SOLVBTC_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, SOLVBTCENA_SLOT));

        assertTrue(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(SOLVBTC_SFT, SOLVBTC_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, GMXBTCA_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, GMXBTCB_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, SOLVBTC_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, SOLVBTCENA_SLOT));

        assertEq(solvBTCMultiAssetPool.getERC20(SOLVBTC_SFT, SOLVBTC_SLOT), address(solvBTC));
        assertEq(solvBTCMultiAssetPool.getERC20(FUND_SFT, GMXBTCA_SLOT), address(gmxBTC));
        assertEq(solvBTCMultiAssetPool.getERC20(FUND_SFT, GMXBTCB_SLOT), address(gmxBTC));

        assertEq(solvBTCMultiAssetPool.getHoldingValueSftId(SOLVBTC_SFT, SOLVBTC_SLOT), SOLVBTC_HOLDING_VALUE_SFT_ID);
        assertEq(solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCA_SLOT), 0);
        assertEq(solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCB_SLOT), 0);

        assertEq(
            solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT),
            IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID)
        );
        assertEq(solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCA_SLOT), 0);
        assertEq(solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCB_SLOT), 0);
    }

    function test_RemoveSftSlot() public {
        _addDefaultSftSlots();
        vm.startPrank(ADMIN);
        solvBTCMultiAssetPool.changeSftSlotAllowedOnlyAdmin(FUND_SFT, GMXBTCB_SLOT, false, false);
        assertTrue(solvBTCMultiAssetPool.isSftSlotDepositAllowed(SOLVBTC_SFT, SOLVBTC_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(SOLVBTC_SFT, SOLVBTC_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, GMXBTCA_SLOT));
        assertTrue(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, GMXBTCA_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotDepositAllowed(FUND_SFT, GMXBTCB_SLOT));
        assertFalse(solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(FUND_SFT, GMXBTCB_SLOT));
        vm.stopPrank();
    }

    /**
     * Tests for deposit/withdraw
     */
    function test_FullDepositWhenHoldingValueSftIdIsNotZero() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 user1BalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 user2BalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 depositValue1 = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, depositValue1);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        uint256 depositValue2 = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_2);
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_2, depositValue2);
        vm.stopPrank();

        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 user1BalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 user2BalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyAfter - totalSupplyBefore, depositValue1 + depositValue2);
        assertEq(user1BalanceAfter - user1BalanceBefore, depositValue1);
        assertEq(user2BalanceAfter - user2BalanceBefore, depositValue2);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, depositValue1 + depositValue2);
    }

    function test_FullDepositWhenHoldingValueSftIdIsZero() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = gmxBTC.totalSupply();
        uint256 userA1BalanceBefore = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_1);
        uint256 userA2BalanceBefore = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_2);
        uint256 userB1BalanceBefore = gmxBTC.balanceOf(GMXBTCB_SFT_HOLDER_1);

        vm.startPrank(GMXBTCA_SFT_HOLDER_1);
        uint256 depositValueA1 = IERC3525(FUND_SFT).balanceOf(GMXBTCA_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCA_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCA_SFT_ID_1, depositValueA1);
        vm.stopPrank();

        vm.startPrank(GMXBTCA_SFT_HOLDER_2);
        uint256 depositValueA2 = IERC3525(FUND_SFT).balanceOf(GMXBTCA_SFT_ID_2);
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCA_SFT_ID_2);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCA_SFT_ID_2, depositValueA2);
        vm.stopPrank();

        vm.startPrank(GMXBTCB_SFT_HOLDER_1);
        uint256 depositValueB1 = IERC3525(FUND_SFT).balanceOf(GMXBTCB_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCB_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCB_SFT_ID_1, depositValueB1);
        vm.stopPrank();

        GMXBTCA_HOLDING_VALUE_SFT_ID = solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCA_SLOT);
        GMXBTCB_HOLDING_VALUE_SFT_ID = solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCB_SLOT);
        assertNotEq(GMXBTCA_HOLDING_VALUE_SFT_ID, 0);
        assertNotEq(GMXBTCB_HOLDING_VALUE_SFT_ID, 0);

        uint256 totalSupplyAfter = gmxBTC.totalSupply();
        uint256 userA1BalanceAfter = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_1);
        uint256 userA2BalanceAfter = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_2);
        uint256 userB1BalanceAfter = gmxBTC.balanceOf(GMXBTCB_SFT_HOLDER_1);
        uint256 poolHoldingAValueAfter = IERC3525(FUND_SFT).balanceOf(GMXBTCA_HOLDING_VALUE_SFT_ID);
        uint256 poolHoldingBValueAfter = IERC3525(FUND_SFT).balanceOf(GMXBTCB_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyAfter - totalSupplyBefore, depositValueA1 + depositValueA2 + depositValueB1);
        assertEq(userA1BalanceAfter - userA1BalanceBefore, depositValueA1);
        assertEq(userA2BalanceAfter - userA2BalanceBefore, depositValueA2);
        assertEq(userB1BalanceAfter - userB1BalanceBefore, depositValueB1);
        assertEq(poolHoldingAValueAfter, depositValueA1 + depositValueA2);
        assertEq(poolHoldingBValueAfter, depositValueB1);
    }

    function test_PartialDepositWhenHoldingValueSftIdIsNotZero() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 user1BalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 user2BalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 depositValue1 = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1) / 4;
        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_1, address(solvBTCMultiAssetPool), depositValue1);
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, depositValue1);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        uint256 depositValue2 = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2) / 4;
        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_2, address(solvBTCMultiAssetPool), depositValue2);
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_2, depositValue2);
        vm.stopPrank();

        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 user1BalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 user2BalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyAfter - totalSupplyBefore, depositValue1 + depositValue2);
        assertEq(user1BalanceAfter - user1BalanceBefore, depositValue1);
        assertEq(user2BalanceAfter - user2BalanceBefore, depositValue2);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, depositValue1 + depositValue2);
    }

    function test_PartialDepositWhenHoldingValueSftIdIsZero() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = gmxBTC.totalSupply();
        uint256 userA1BalanceBefore = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_1);
        uint256 userA2BalanceBefore = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_2);
        uint256 userB1BalanceBefore = gmxBTC.balanceOf(GMXBTCB_SFT_HOLDER_1);

        vm.startPrank(GMXBTCA_SFT_HOLDER_1);
        uint256 depositValueA1 = IERC3525(FUND_SFT).balanceOf(GMXBTCA_SFT_ID_1) / 4;
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCA_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCA_SFT_ID_1, depositValueA1);
        vm.stopPrank();

        vm.startPrank(GMXBTCA_SFT_HOLDER_2);
        uint256 depositValueA2 = IERC3525(FUND_SFT).balanceOf(GMXBTCA_SFT_ID_2) / 4;
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCA_SFT_ID_2);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCA_SFT_ID_2, depositValueA2);
        vm.stopPrank();

        vm.startPrank(GMXBTCB_SFT_HOLDER_1);
        uint256 depositValueB1 = IERC3525(FUND_SFT).balanceOf(GMXBTCB_SFT_ID_1) / 4;
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCB_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCB_SFT_ID_1, depositValueB1);
        vm.stopPrank();

        GMXBTCA_HOLDING_VALUE_SFT_ID = solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCA_SLOT);
        GMXBTCB_HOLDING_VALUE_SFT_ID = solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCB_SLOT);
        assertNotEq(GMXBTCA_HOLDING_VALUE_SFT_ID, 0);
        assertNotEq(GMXBTCB_HOLDING_VALUE_SFT_ID, 0);

        uint256 totalSupplyAfter = gmxBTC.totalSupply();
        uint256 userA1BalanceAfter = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_1);
        uint256 userA2BalanceAfter = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_2);
        uint256 userB1BalanceAfter = gmxBTC.balanceOf(GMXBTCB_SFT_HOLDER_1);
        uint256 poolHoldingAValueAfter = IERC3525(FUND_SFT).balanceOf(GMXBTCA_HOLDING_VALUE_SFT_ID);
        uint256 poolHoldingBValueAfter = IERC3525(FUND_SFT).balanceOf(GMXBTCB_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyAfter - totalSupplyBefore, depositValueA1 + depositValueA2 + depositValueB1);
        assertEq(userA1BalanceAfter - userA1BalanceBefore, depositValueA1);
        assertEq(userA2BalanceAfter - userA2BalanceBefore, depositValueA2);
        assertEq(userB1BalanceAfter - userB1BalanceBefore, depositValueB1);
        assertEq(poolHoldingAValueAfter, depositValueA1 + depositValueA2);
        assertEq(poolHoldingBValueAfter, depositValueB1);
    }

    function test_WithdrawSlotAAfterDepositSlotA() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 depositValue1 = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, depositValue1);
        vm.stopPrank();

        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        uint256 solvBTCSftHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue1 = userBalanceBefore / 4;
        uint256 withdrawValue2 = userBalanceBefore / 2;
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue1 + withdrawValue2);
        // withdraw to non-specified sftId
        uint256 toSftId = solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, 0, withdrawValue1);
        // withdraw to specified sftId
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, toSftId, withdrawValue2);
        vm.stopPrank();

        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        uint256 solvBTCSftHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyBefore - totalSupplyAfter, withdrawValue1 + withdrawValue2);
        assertEq(userBalanceBefore - userBalanceAfter, withdrawValue1 + withdrawValue2);
        assertEq(solvBTCSftHoldingValueBefore - solvBTCSftHoldingValueAfter, withdrawValue1 + withdrawValue2);

        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(toSftId), withdrawValue1 + withdrawValue2);
        assertEq(IERC3525(SOLVBTC_SFT).slotOf(toSftId), SOLVBTC_SLOT);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(toSftId), SOLVBTC_HOLDER_1);
    }

    function test_WithdrawSlotBAfterDepositSlotA() public {
        _addDefaultSftSlots();
        vm.startPrank(GMXBTCB_SFT_HOLDER_1);
        uint256 depositValueB1 = IERC3525(FUND_SFT).balanceOf(GMXBTCB_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCB_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCB_SFT_ID_1, depositValueB1);
        vm.stopPrank();

        vm.startPrank(GMXBTCA_SFT_HOLDER_1);
        uint256 depositValueA1 = IERC3525(FUND_SFT).balanceOf(GMXBTCA_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCA_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCA_SFT_ID_1, depositValueA1);
        vm.stopPrank();

        GMXBTCA_HOLDING_VALUE_SFT_ID = solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCA_SLOT);
        GMXBTCB_HOLDING_VALUE_SFT_ID = solvBTCMultiAssetPool.getHoldingValueSftId(FUND_SFT, GMXBTCB_SLOT);
        uint256 totalSupplyBefore = gmxBTC.totalSupply();
        uint256 userA1BalanceBefore = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_1);
        uint256 gmxBTCASftHoldingValueBefore = IERC3525(FUND_SFT).balanceOf(GMXBTCA_HOLDING_VALUE_SFT_ID);
        uint256 gmxBTCBSftHoldingValueBefore = IERC3525(FUND_SFT).balanceOf(GMXBTCB_HOLDING_VALUE_SFT_ID);

        vm.startPrank(GMXBTCA_SFT_HOLDER_1);
        uint256 withdrawValue1 = userA1BalanceBefore / 4;
        uint256 withdrawValue2 = userA1BalanceBefore / 2;
        gmxBTC.approve(address(solvBTCMultiAssetPool), withdrawValue1 + withdrawValue2);
        // withdraw to non-specified sftId
        uint256 toSftId = solvBTCMultiAssetPool.withdraw(FUND_SFT, GMXBTCB_SLOT, 0, withdrawValue1);
        // withdraw to specified sftId
        solvBTCMultiAssetPool.withdraw(FUND_SFT, GMXBTCB_SLOT, toSftId, withdrawValue2);
        vm.stopPrank();

        uint256 totalSupplyAfter = gmxBTC.totalSupply();
        uint256 userA1BalanceAfter = gmxBTC.balanceOf(GMXBTCA_SFT_HOLDER_1);
        uint256 gmxBTCASftHoldingValueAfter = IERC3525(FUND_SFT).balanceOf(GMXBTCA_HOLDING_VALUE_SFT_ID);
        uint256 gmxBTCBSftHoldingValueAfter = IERC3525(FUND_SFT).balanceOf(GMXBTCB_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyBefore - totalSupplyAfter, withdrawValue1 + withdrawValue2);
        assertEq(userA1BalanceBefore - userA1BalanceAfter, withdrawValue1 + withdrawValue2);
        assertEq(gmxBTCASftHoldingValueBefore, gmxBTCASftHoldingValueAfter);
        assertEq(gmxBTCBSftHoldingValueBefore - gmxBTCBSftHoldingValueAfter, withdrawValue1 + withdrawValue2);

        assertEq(IERC3525(FUND_SFT).balanceOf(toSftId), withdrawValue1 + withdrawValue2);
        assertEq(IERC3525(FUND_SFT).slotOf(toSftId), GMXBTCB_SLOT);
        assertEq(IERC3525(FUND_SFT).ownerOf(toSftId), GMXBTCA_SFT_HOLDER_1);
    }

    function test_WithdrawForThoseWhoDepositBeforeUpgrade() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        uint256 solvBTCSftHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue1 = userBalanceBefore / 4;
        uint256 withdrawValue2 = userBalanceBefore / 2;
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue1 + withdrawValue2);
        // withdraw to non-specified sftId
        uint256 toSftId = solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, 0, withdrawValue1);
        // withdraw to specified sftId
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, toSftId, withdrawValue2);
        vm.stopPrank();

        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        uint256 solvBTCSftHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(totalSupplyBefore - totalSupplyAfter, withdrawValue1 + withdrawValue2);
        assertEq(userBalanceBefore - userBalanceAfter, withdrawValue1 + withdrawValue2);
        assertEq(solvBTCSftHoldingValueBefore - solvBTCSftHoldingValueAfter, withdrawValue1 + withdrawValue2);

        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(toSftId), withdrawValue1 + withdrawValue2);
        assertEq(IERC3525(SOLVBTC_SFT).slotOf(toSftId), SOLVBTC_SLOT);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(toSftId), SOLVBTC_HOLDER_1);
    }

    /**
     * Exception test for add/remove sft slots
     */
    function test_RevertWhenAddSftSlotByNonAdmin() public {
        vm.startPrank(USER);
        vm.expectRevert("only admin");
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(
            SOLVBTC_SFT, SOLVBTC_SLOT, address(solvBTC), SOLVBTC_HOLDING_VALUE_SFT_ID
        );
        vm.stopPrank();
    }

    function test_RevertWhenAddExistedSftSlot() public {
        _addDefaultSftSlots();
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCMultiAssetPool: sft slot already existed");
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(
            SOLVBTC_SFT, SOLVBTC_SLOT, address(solvBTC), SOLVBTC_HOLDING_VALUE_SFT_ID
        );
        vm.stopPrank();
    }

    function test_RevertWhenAddSftSlotWithSftIdOfMismatchedSlot() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCMultiAssetPool: slot not matched");
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(FUND_SFT, GMXBTCB_SLOT, address(gmxBTC), 1);
        vm.stopPrank();
    }

    function test_RevertWhenAddSftSlotWithSftIdNotOwned() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCMultiAssetPool: sftId not owned");
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(FUND_SFT, GMXBTCB_SLOT, address(gmxBTC), 369);
        vm.stopPrank();
    }

    function test_RevertWhenDecimalsNotMatched() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCMultiAssetPool: decimals not matched");
        address USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(FUND_SFT, GMXBTCB_SLOT, USDT, 0);
        vm.stopPrank();
    }

    function test_RevertWhenchangeSftSlotAllowedByNonAdmin() public {
        _addDefaultSftSlots();
        vm.startPrank(USER);
        vm.expectRevert("only admin");
        solvBTCMultiAssetPool.changeSftSlotAllowedOnlyAdmin(FUND_SFT, GMXBTCB_SLOT, false, false);
        vm.stopPrank();
    }

    /**
     * Exception test for deposit/withdraw
     */
    function test_RevertWhenDepositValueIsZero() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_1);
        vm.expectRevert("SolvBTCMultiAssetPool: deposit amount cannot be 0");
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, 0);
        vm.stopPrank();
    }

    function test_RevertWhenDepositValueExceedsSftIdBalance() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 depositValue = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_1);
        vm.expectRevert("SolvBTCMultiAssetPool: deposit amount exceeds sft balance");
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, depositValue + 1);
        vm.stopPrank();
    }

    function test_RevertWhenDepositToInvalidSftSlot() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 depositValue = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_1);
        vm.expectRevert("SolvBTCMultiAssetPool: sft slot deposit not allowed");
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, depositValue);
        vm.stopPrank();
    }

    function test_RevertWhenDepositWithSftIdNotOwned() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        IERC3525(SOLVBTC_SFT).approve(address(solvBTCMultiAssetPool), SOLVBTC_SFT_ID_1);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        uint256 depositValue = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        vm.expectRevert("SolvBTCMultiAssetPool: caller is not sft owner");
        solvBTCMultiAssetPool.deposit(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, depositValue);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawValueIsZero() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        vm.expectRevert("SolvBTCMultiAssetPool: withdraw amount cannot be 0");
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, 0, 0);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawValueExceedsBalance() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue + 1);
        vm.expectRevert(
            abi.encodeWithSignature(
                "ERC20InsufficientBalance(address,uint256,uint256)", SOLVBTC_HOLDER_1, withdrawValue, withdrawValue + 1
            )
        );
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, 0, withdrawValue + 1);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawToInvalidSftSlot() public {
        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        vm.expectRevert("SolvBTCMultiAssetPool: sft slot not allowed");
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, 0, withdrawValue);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawButPoolHoldingValueSftIdIsZero() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        vm.expectRevert("SolvBTCMultiAssetPool: insufficient balance");
        solvBTCMultiAssetPool.withdraw(FUND_SFT, GMXBTCB_SLOT, 0, withdrawValue);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawButPoolHoldingValueNotEnough() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 solvBTCSftHoldingValue = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        vm.mockCall(
            address(solvBTC),
            abi.encodeWithSignature("balanceOf(address)", SOLVBTC_HOLDER_1),
            abi.encode(solvBTCSftHoldingValue + 1)
        );
        uint256 withdrawValue = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        vm.expectRevert("SolvBTCMultiAssetPool: insufficient balance");
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, 0, withdrawValue);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawWithMismatchedSpecifiedSlot() public {
        _addDefaultSftSlots();
        vm.startPrank(GMXBTCB_SFT_HOLDER_1);
        uint256 depositValue = IERC3525(FUND_SFT).balanceOf(GMXBTCB_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(solvBTCMultiAssetPool), GMXBTCB_SFT_ID_1);
        solvBTCMultiAssetPool.deposit(FUND_SFT, GMXBTCB_SFT_ID_1, depositValue);

        uint256 withdrawValue = depositValue / 2;
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        vm.expectRevert("SolvBTCMultiAssetPool: slot not matched");
        solvBTCMultiAssetPool.withdraw(FUND_SFT, GMXBTCB_SLOT, GMXBTCA_SFT_ID_1, withdrawValue);
        vm.stopPrank();
    }

    function test_RevertWhenWithdrawToSftIdNotOwned() public {
        _addDefaultSftSlots();
        vm.startPrank(SOLVBTC_HOLDER_1);
        uint256 withdrawValue = solvBTC.balanceOf(SOLVBTC_HOLDER_1);
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        vm.expectRevert("SolvBTCMultiAssetPool: caller is not sft owner");
        solvBTCMultiAssetPool.withdraw(SOLVBTC_SFT, SOLVBTC_SLOT, SOLVBTC_SFT_ID_1, withdrawValue);
        vm.stopPrank();
    }

    /**
     * Internal functions
     */
    function _deploySolvBTCMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize()")
        );
        solvBTCMultiAssetPool = SolvBTCMultiAssetPool(address(proxy));
        vm.stopPrank();
    }

    function _upgradeSolvBTC() internal {
        vm.startPrank(ADMIN);
        SolvBTC solvBTCImpl = new SolvBTC();
        factory.setImplementation(PRODUCT_TYPE, address(solvBTCImpl));
        factory.upgradeBeacon(PRODUCT_TYPE);
        vm.stopPrank();
    }

    function _setupSolvBTC() internal {
        vm.startPrank(ADMIN);
        solvBTC.initializeV2(address(solvBTCMultiAssetPool));
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }

    function _deployGmxBTC() internal {
        vm.startPrank(ADMIN);
        SolvBTC gmxBTCImpl = new SolvBTC();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(gmxBTCImpl), address(proxyAdmin), 
            abi.encodeWithSignature("initialize(string,string)", "GmxBTC", "GmxBTC")
        );
        gmxBTC = SolvBTC(address(proxy));
        gmxBTC.initializeV2(address(solvBTCMultiAssetPool));
        gmxBTC.grantRole(gmxBTC.SOLVBTC_MINTER_ROLE(), address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }

    function _addDefaultSftSlots() internal {
        vm.startPrank(ADMIN);
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(
            SOLVBTC_SFT, SOLVBTC_SLOT, address(solvBTC), SOLVBTC_HOLDING_VALUE_SFT_ID
        );
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(FUND_SFT, GMXBTCA_SLOT, address(gmxBTC), 0);
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(FUND_SFT, GMXBTCB_SLOT, address(gmxBTC), 0);
        vm.stopPrank();
    }
}
