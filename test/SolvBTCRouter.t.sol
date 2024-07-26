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

contract SolvBTCRouterTest is Test {
    string internal constant PRODUCT_TYPE_SOLVBTC = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME_SOLVBTC = "Solv BTC";

    address internal constant MARKET_ADDRESS = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address internal constant WHITELIST_MANAGER_ADDRESS = 0x8f694b722b32ab9fe7959D8398cD61b70CdE58db;
    address internal constant FOF_NAV_ORACLE_ADDRESS = 0xc09022C379eE2bee0Da72813C0C84c3Ed8521251;
    address internal constant WBTC_ADDRESS = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address internal constant SOLVBTC_SFT = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    address internal constant SOLVBTC_REDEMPTION_SFT_ADDRESS = 0x5d931F572df1cd730F1ADf3F9Eb5B218D2cE641f;
    uint256 internal constant SOLVBTC_SLOT =
        39475026322910990648776764986670533412889479187054865546374468496663502783148;
    bytes32 internal constant SOLVBTC_POOL_ID = 0x488def4a346b409d5d57985a160cd216d29d4f555e1b716df4e04e2374d2d9f6;
    uint256 internal constant SOLVBTC_HOLDING_VALUE_SFT_ID = 72;

    uint256 internal constant SOLVBTC_SFT_ID_1 = 66;
    address internal constant SOLVBTC_SFT_HOLDER_1 = 0x07a1f6fc89223c5ebD4e4ddaE89Ac97629856A0f;
    uint256 internal constant SOLVBTC_SFT_ID_2 = 77;
    address internal constant SOLVBTC_SFT_HOLDER_2 = 0xFc220fB83314B4b1E00421777CB579a68f17c439;

    bytes32 internal constant SOLVBTCENA_POOL_ID = 0x0e11a7249a1ca69c4ed42b0bfcc0e3d8f45de5e510c0d866132fdf078f3849df;

    address internal constant SUBSCRIBER = 0xD0CD13117f8C5022e9322da35c075cFA147aEa8a;

    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant GOVERNOR = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;

    address internal constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    SftWrappedTokenFactory public factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);
    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCMultiAssetPool internal solvBTCMultiAssetPool;
    SolvBTCRouter internal router;

    function setUp() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        _setupSolvBTC();
        _setupMultiAssetPool();
        _deploySolvBTCRouter();
    }

    function test_RouterInitialStatus() public {
        assertEq(router.admin(), ADMIN);
        assertEq(router.governor(), GOVERNOR);
        assertEq(router.openFundMarket(), MARKET_ADDRESS);
        assertEq(router.solvBTCMultiAssetPool(), address(solvBTCMultiAssetPool));
    }

    function test_ERC165() public {
        assertTrue(router.supportsInterface(type(IERC3525Receiver).interfaceId));
        assertTrue(router.supportsInterface(type(IERC721Receiver).interfaceId));
        assertTrue(router.supportsInterface(type(IERC165).interfaceId));
    }

    /**
     * Tests for onERC721Received
     */
    function test_SolvBTC_OnERC721Received_FirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        IERC3525(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER_1, address(router), SOLVBTC_SFT_ID_1);
        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, solvBTCSft1BalanceBefore);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, solvBTCSft1BalanceBefore);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, solvBTCSft1BalanceBefore);
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), DEAD_ADDRESS);
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT), 0);
        vm.stopPrank();
    }

    function test_SolvBTC_OnERC721Received_NotFirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        IERC3525(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER_2, address(router), SOLVBTC_SFT_ID_2);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        IERC3525(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER_1, address(router), SOLVBTC_SFT_ID_1);
        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, solvBTCSft1BalanceBefore);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, solvBTCSft1BalanceBefore);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, solvBTCSft1BalanceBefore);
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), DEAD_ADDRESS);
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT), 0);
        vm.stopPrank();
    }

    /**
     * Tests for onERC3525Received
     */
    function test_SolvBTC_OnERC3525Received_FirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        uint256 stakeValue = solvBTCSft1BalanceBefore / 4;
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID_1, address(router), stakeValue);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);

        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, stakeValue);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, stakeValue);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, stakeValue);
        assertEq(solvBTCSft1BalanceBefore - solvBTCSft1BalanceAfter, stakeValue);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), SOLVBTC_SFT_HOLDER_1);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(routerHoldingSftId), address(router));
        vm.stopPrank();
    }

    function test_SolvBTC_OnERC3525Received_NotFirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        uint256 solvBTCSft2Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2);
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID_2, address(router), solvBTCSft2Balance);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        uint256 stakeValue = solvBTCSft1BalanceBefore / 4;
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID_1, routerHoldingSftId, stakeValue);
        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, stakeValue);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, stakeValue);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, stakeValue);
        assertEq(solvBTCSft1BalanceBefore - solvBTCSft1BalanceAfter, stakeValue);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), SOLVBTC_SFT_HOLDER_1);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(routerHoldingSftId), address(router));
        vm.stopPrank();
    }

    /**
     * Tests for stake function
     */
    function test_FirstStakeWithAllValue() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 poolHoldingValueBefore = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);

        IERC3525(SOLVBTC_SFT).approve(address(router), SOLVBTC_SFT_ID_1);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, sft1Balance);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 poolHoldingValueAfter = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);

        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, sft1Balance);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, sft1Balance);
        assertEq(routerHoldingSftId, 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), DEAD_ADDRESS);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1), 0);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID), poolHoldingValueBefore + sft1Balance);
        vm.stopPrank();
    }

    function test_FirstStakeWithPartialValue() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 poolHoldingValueBefore = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 stakeValue = sft1Balance / 4;

        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_1, address(router), stakeValue);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, stakeValue);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 poolHoldingValueAfter = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);

        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, stakeValue);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, stakeValue);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), SOLVBTC_SFT_HOLDER_1);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1), sft1Balance - stakeValue);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID), poolHoldingValueBefore + stakeValue);
        vm.stopPrank();
    }

    function test_NonFirstStakeWithAllValue() public {
        uint256 poolHoldingValueBefore = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 solvBTCBalance1Before = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCBalance2Before = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 sft1Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 sft2Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2);

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        IERC3525(SOLVBTC_SFT).approve(address(router), SOLVBTC_SFT_ID_1);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, sft1Balance);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        IERC3525(SOLVBTC_SFT).approve(address(router), SOLVBTC_SFT_ID_2);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_2, sft2Balance);
        vm.stopPrank();

        uint256 solvBTCBalance1After = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCBalance2After = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 poolHoldingValueAfter = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);

        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, sft1Balance + sft2Balance);
        assertEq(solvBTCBalance1After - solvBTCBalance1Before, sft1Balance);
        assertEq(solvBTCBalance2After - solvBTCBalance2Before, sft2Balance);
        assertEq(routerHoldingSftId, 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), DEAD_ADDRESS);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_2), DEAD_ADDRESS);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1), 0);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2), 0);
        assertEq(
            IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID),
            poolHoldingValueBefore + sft1Balance + sft2Balance
        );
    }

    function test_NonFirstStakeWithPartialValue() public {
        uint256 poolHoldingValueBefore = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 solvBTCBalance1Before = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCBalance2Before = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 sft1Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 sft2Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2);

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 stakeValue1 = sft1Balance / 4;
        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_1, address(router), stakeValue1);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, stakeValue1);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        uint256 stakeValue2 = sft2Balance / 2;
        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_2, address(router), stakeValue2);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_2, stakeValue2);
        vm.stopPrank();

        uint256 solvBTCBalance1After = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCBalance2After = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_2);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);
        uint256 poolHoldingValueAfter = solvBTCMultiAssetPool.getSftSlotBalance(SOLVBTC_SFT, SOLVBTC_SLOT);

        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, stakeValue1 + stakeValue2);
        assertEq(solvBTCBalance1After - solvBTCBalance1Before, stakeValue1);
        assertEq(solvBTCBalance2After - solvBTCBalance2Before, stakeValue2);
        assertNotEq(routerHoldingSftId, 0);

        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), SOLVBTC_SFT_HOLDER_1);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_2), SOLVBTC_SFT_HOLDER_2);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1), sft1Balance - stakeValue1);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2), sft2Balance - stakeValue2);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(
            IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID),
            poolHoldingValueBefore + stakeValue1 + stakeValue2
        );
    }

    /**
     * Tests for unstake function
     */
    function test_UnstakeWhenGivenSftId() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 stakeValue = sft1Balance / 2;
        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_1, address(router), stakeValue);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, stakeValue);

        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);

        uint256 unstakeAmount = stakeValue / 2;
        solvBTC.approve(address(router), unstakeAmount);
        uint256 toSftId = router.unstake(address(solvBTC), unstakeAmount, SOLVBTC_SFT, SOLVBTC_SLOT, SOLVBTC_SFT_ID_1);

        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);

        assertEq(toSftId, SOLVBTC_SFT_ID_1);
        assertEq(solvBTCBalanceBefore - solvBTCBalanceAfter, unstakeAmount);
        assertEq(sft1BalanceAfter - sft1BalanceBefore, unstakeAmount);
        assertEq(poolHoldingValueBefore - poolHoldingValueAfter, unstakeAmount);
        vm.stopPrank();
    }

    function test_UnstakeWhenNotGivenSftId() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 stakeValue = sft1Balance / 2;
        IERC3525(SOLVBTC_SFT).approve(SOLVBTC_SFT_ID_1, address(router), stakeValue);
        router.stake(SOLVBTC_SFT, SOLVBTC_SFT_ID_1, stakeValue);

        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);

        uint256 unstakeAmount = stakeValue / 2;
        solvBTC.approve(address(router), unstakeAmount);
        uint256 toSftId = router.unstake(address(solvBTC), unstakeAmount, SOLVBTC_SFT, SOLVBTC_SLOT, 0);

        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 sft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 toSftIdBalance = IERC3525(SOLVBTC_SFT).balanceOf(toSftId);

        assertNotEq(toSftId, SOLVBTC_SFT_ID_1);
        assertEq(toSftIdBalance, unstakeAmount);
        assertEq(solvBTCBalanceBefore - solvBTCBalanceAfter, unstakeAmount);
        assertEq(sft1BalanceBefore, sft1BalanceAfter);
        assertEq(poolHoldingValueBefore - poolHoldingValueAfter, unstakeAmount);
        vm.stopPrank();
    }

    /**
     * Tests for subscribe/redeem functions
     */
    function test_CreateSubscription() public {
        vm.startPrank(SUBSCRIBER);
        uint256 currencyBalanceBefore = ERC20(WBTC_ADDRESS).balanceOf(SUBSCRIBER);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SUBSCRIBER);
        uint256 subscribeCurrencyAmount = 1e8;

        ERC20(WBTC_ADDRESS).approve(address(router), subscribeCurrencyAmount);
        router.createSubscription(SOLVBTC_POOL_ID, subscribeCurrencyAmount);
        uint256 currencyBalanceAfter = ERC20(WBTC_ADDRESS).balanceOf(SUBSCRIBER);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SUBSCRIBER);

        assertEq(currencyBalanceBefore - currencyBalanceAfter, subscribeCurrencyAmount);
        uint256 nav = _getSubscribeNav(SOLVBTC_POOL_ID, block.timestamp);
        uint256 dueSolvBTCAmount = subscribeCurrencyAmount * (10 ** solvBTC.decimals()) / nav;
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, dueSolvBTCAmount);
        vm.stopPrank();
    }

    function test_CreateRedemption() public {
        vm.startPrank(SUBSCRIBER);
        uint256 subscribeCurrencyAmount = 1e8;
        ERC20(WBTC_ADDRESS).approve(address(router), subscribeCurrencyAmount);
        router.createSubscription(SOLVBTC_POOL_ID, subscribeCurrencyAmount);

        vm.warp(1725148800);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SUBSCRIBER);
        uint256 redeemAmount = 0.5 ether;
        solvBTC.approve(address(router), redeemAmount);
        router.createRedemption(SOLVBTC_POOL_ID, redeemAmount);

        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SUBSCRIBER);
        assertEq(solvBTCBalanceBefore - solvBTCBalanceAfter, redeemAmount);

        uint256 redemptionId = _getLastSftIdOwned(SOLVBTC_REDEMPTION_SFT_ADDRESS, SUBSCRIBER);
        uint256 redemptionBalance = IERC3525(SOLVBTC_REDEMPTION_SFT_ADDRESS).balanceOf(redemptionId);
        assertEq(redemptionBalance, redeemAmount);
        vm.stopPrank();
    }

    function test_CancelRedemption() public {
        vm.startPrank(SUBSCRIBER);
        uint256 subscribeCurrencyAmount = 1e8;
        ERC20(WBTC_ADDRESS).approve(address(router), subscribeCurrencyAmount);
        router.createSubscription(SOLVBTC_POOL_ID, subscribeCurrencyAmount);

        vm.warp(1725148800);
        uint256 redeemAmount = 0.5 ether;
        solvBTC.approve(address(router), redeemAmount);
        router.createRedemption(SOLVBTC_POOL_ID, redeemAmount);
        uint256 redemptionId = _getLastSftIdOwned(SOLVBTC_REDEMPTION_SFT_ADDRESS, SUBSCRIBER);

        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SUBSCRIBER);
        IERC3525(SOLVBTC_REDEMPTION_SFT_ADDRESS).approve(address(router), redemptionId);
        router.cancelRedemption(SOLVBTC_POOL_ID, redemptionId);

        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SUBSCRIBER);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, redeemAmount);

        vm.expectRevert("ERC3525: invalid token ID");
        IERC3525(SOLVBTC_REDEMPTION_SFT_ADDRESS).ownerOf(redemptionId);
        vm.stopPrank();
    }

    function test_RevertWhenSubscriberNotInWhitelist() public {
        PoolInfo memory poolInfo = IOpenFundMarket(MARKET_ADDRESS).poolInfos(SOLVBTC_POOL_ID);
        poolInfo.permissionless = false;
        vm.mockCall(
            MARKET_ADDRESS, abi.encodeWithSignature("poolInfos(bytes32)", SOLVBTC_POOL_ID), abi.encode(poolInfo)
        );
        vm.mockCall(
            WHITELIST_MANAGER_ADDRESS,
            abi.encodeWithSignature("isWhitelisted(bytes32,address)", SOLVBTC_POOL_ID, SUBSCRIBER),
            abi.encode(false)
        );

        vm.startPrank(SUBSCRIBER);
        uint256 subscribeCurrencyAmount = 1e8;
        ERC20(WBTC_ADDRESS).approve(address(router), subscribeCurrencyAmount);
        vm.expectRevert("SolvBTCRouter: pool permission denied");
        router.createSubscription(SOLVBTC_POOL_ID, subscribeCurrencyAmount);
        vm.stopPrank();
    }

    function test_RevertWhenCreateRedemptionWithInvalidPoolId() public {
        vm.startPrank(SUBSCRIBER);
        vm.expectRevert("SolvBTCRouter: sft slot not allowed");
        router.createRedemption(SOLVBTCENA_POOL_ID, 1 ether);
        vm.stopPrank();
    }

    /**
     * Tests for setups
     */
    function test_SetOpenFundMarket() public {
        vm.startPrank(ADMIN);
        address newMockMarket = makeAddr("Mock OpenFundMarket");
        router.setOpenFundMarket(newMockMarket);
        assertEq(router.openFundMarket(), newMockMarket);
        vm.stopPrank();
    }

    function test_SetSolvBTCMultiAssetPool() public {
        vm.startPrank(ADMIN);
        address newSolvBTCMultiAssetPool = makeAddr("Mock SolvBTCMultiAssetPool");
        router.setSolvBTCMultiAssetPool(newSolvBTCMultiAssetPool);
        assertEq(router.solvBTCMultiAssetPool(), newSolvBTCMultiAssetPool);
        vm.stopPrank();
    }

    function test_RevertWhenSetOpenFundMarketByNonAdmin() public {
        vm.startPrank(SUBSCRIBER);
        address newMockMarket = makeAddr("Mock OpenFundMarket");
        vm.expectRevert("only admin");
        router.setOpenFundMarket(newMockMarket);
        vm.stopPrank();
    }

    function test_RevertWhenSetOpenFundMarketWithInvalidAddress() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCRouter: invalid openFundMarket");
        router.setOpenFundMarket(address(0));
        vm.stopPrank();
    }

    function test_RevertWhenSetSolvBTCMultiAssetPoolByNonAdmin() public {
        vm.startPrank(SUBSCRIBER);
        address newSolvBTCMultiAssetPool = makeAddr("Mock SolvBTCMultiAssetPool");
        vm.expectRevert("only admin");
        router.setSolvBTCMultiAssetPool(newSolvBTCMultiAssetPool);
        vm.stopPrank();
    }

    function test_RevertWhenSetSolvBTCMultiAssetPoolWithInvalidAddress() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCRouter: invalid solvBTCMultiAssetPool");
        router.setSolvBTCMultiAssetPool(address(0));
        vm.stopPrank();
    }

    /**
     * Internal functions
     */
    function _deploySolvBTCMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize()")
        );
        solvBTCMultiAssetPool = SolvBTCMultiAssetPool(address(proxy));
        vm.stopPrank();
    }

    function _upgradeSolvBTC() internal {
        vm.startPrank(ADMIN);
        SolvBTC solvBTCImpl = new SolvBTC();
        factory.setImplementation(PRODUCT_TYPE_SOLVBTC, address(solvBTCImpl));
        factory.upgradeBeacon(PRODUCT_TYPE_SOLVBTC);
        vm.stopPrank();
    }

    function _setupSolvBTC() internal {
        vm.startPrank(ADMIN);
        solvBTC.initializeV2(address(solvBTCMultiAssetPool));
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }

    function _setupMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(
            SOLVBTC_SFT, SOLVBTC_SLOT, address(solvBTC), SOLVBTC_HOLDING_VALUE_SFT_ID
        );
        vm.stopPrank();
    }

    function _deploySolvBTCRouter() internal {
        vm.startPrank(ADMIN);
        SolvBTCRouter newRouterImpl = new SolvBTCRouter();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(newRouterImpl), address(proxyAdmin), 
            abi.encodeWithSignature("initialize(address,address,address)", GOVERNOR, MARKET_ADDRESS, address(solvBTCMultiAssetPool))
        );
        router = SolvBTCRouter(address(proxy));
        vm.stopPrank();
    }

    function _getSubscribeNav(bytes32 poolId, uint256 timestamp) internal view returns (uint256 nav) {
        (bool success, bytes memory result) = FOF_NAV_ORACLE_ADDRESS.staticcall(
            abi.encodeWithSignature("getSubscribeNav(bytes32,uint256)", poolId, timestamp)
        );
        require(success, "get nav failed");
        (nav,) = abi.decode(result, (uint256, uint256));
    }

    function _getLastSftIdOwned(address sft, address owner) internal view returns (uint256) {
        uint256 balance = IERC3525(sft).balanceOf(owner);
        return IERC3525(sft).tokenOfOwnerByIndex(owner, balance - 1);
    }
}
