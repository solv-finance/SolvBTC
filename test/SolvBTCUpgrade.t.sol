// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "../contracts/SftWrappedTokenFactory.sol";
import "../contracts/SftWrappedToken.sol";
import { SolvBTCUpgrade } from "../contracts/SolvBTCUpgrade.sol";

contract SolvBTCUpgradeTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "Solv BTC";
    string internal constant TOKEN_NAME = "Solv BTC";
    string internal constant TOKEN_SYMBOL = "SolvBTC";

    // run tests for SolvBTC on Arbitrum fork node
    address internal constant SHARE_SFT_ADDRESS = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    bytes32 internal constant SHARE_SFT_POOL_ID = 0x488def4a346b409d5d57985a160cd216d29d4f555e1b716df4e04e2374d2d9f6;
    uint256 internal constant SHARE_SFT_SLOT = 39475026322910990648776764986670533412889479187054865546374468496663502783148;
    address internal constant NAV_ORACLE_ADDRESS = 0xc09022C379eE2bee0Da72813C0C84c3Ed8521251;
    address internal constant WBTC_ADDRESS = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    SftWrappedTokenFactory public factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);

    address public solvBtcProxy;    // solvBTC beacon proxy
    address public solvBtcBeacon;   // solvBTC beacon
    address public solvBtcImpl_v1;  // old version implementation
    address public solvBtcImpl_v2;  // new version implementation

    address public admin = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address public governor = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address public user = 0x005eE35f3eC029b9B637163bCa40A71f329301aD;

    function setUp() public virtual {
        solvBtcProxy = factory.getProxy(PRODUCT_TYPE, PRODUCT_NAME);
        solvBtcBeacon = factory.getBeacon(PRODUCT_TYPE);
        solvBtcImpl_v1 = factory.getImplementation(PRODUCT_TYPE);
        solvBtcImpl_v2 = address(new SolvBTCUpgrade());
    }

    function test_InitialStatusForSolvBTC() public  {
        assertEq(SftWrappedToken(solvBtcProxy).wrappedSftAddress(), SHARE_SFT_ADDRESS);
        assertEq(SftWrappedToken(solvBtcProxy).wrappedSftSlot(), SHARE_SFT_SLOT);
        assertEq(SftWrappedToken(solvBtcProxy).navOracle(), NAV_ORACLE_ADDRESS);
        assertNotEq(SftWrappedToken(solvBtcProxy).holdingValueSftId(), 0);
    }

    function test_Upgrade() public {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, solvBtcImpl_v2);
        factory.upgradeBeacon(PRODUCT_TYPE);
        assertEq(factory.getImplementation(PRODUCT_TYPE), solvBtcImpl_v2);
        assertEq(UpgradeableBeacon(solvBtcBeacon).implementation(), solvBtcImpl_v2);
        vm.stopPrank();

        // check status before upgrade
        assertEq(SolvBTCUpgrade(solvBtcProxy).name(), TOKEN_NAME);
        assertEq(SolvBTCUpgrade(solvBtcProxy).symbol(), TOKEN_SYMBOL);
        assertEq(SolvBTCUpgrade(solvBtcProxy).wrappedSftAddress(), SHARE_SFT_ADDRESS);
        assertEq(SftWrappedToken(solvBtcProxy).wrappedSftSlot(), SHARE_SFT_SLOT);
        assertEq(SftWrappedToken(solvBtcProxy).navOracle(), NAV_ORACLE_ADDRESS);
        assertNotEq(SftWrappedToken(solvBtcProxy).holdingValueSftId(), 0);
        assertEq(SolvBTCUpgrade(solvBtcProxy).underlyingAsset(), address(0));
        assertFalse(SolvBTCUpgrade(solvBtcProxy).isUpgradedToV2());

        uint256 totalSupplyBefore = SolvBTCUpgrade(solvBtcProxy).totalSupply();
        uint256 userBalanceBefore = SolvBTCUpgrade(solvBtcProxy).balanceOf(user);

        SolvBTCUpgrade(solvBtcProxy).upgradeToV2DoOnlyOnce();

        // check status after upgrade
        assertEq(SolvBTCUpgrade(solvBtcProxy).name(), TOKEN_NAME);
        assertEq(SolvBTCUpgrade(solvBtcProxy).symbol(), TOKEN_SYMBOL);
        assertEq(SolvBTCUpgrade(solvBtcProxy).wrappedSftAddress(), address(0));
        assertEq(SftWrappedToken(solvBtcProxy).wrappedSftSlot(), 0);
        assertEq(SftWrappedToken(solvBtcProxy).navOracle(), address(0));
        assertEq(SftWrappedToken(solvBtcProxy).holdingValueSftId(), 0);
        assertEq(SolvBTCUpgrade(solvBtcProxy).underlyingAsset(), WBTC_ADDRESS);
        assertTrue(SolvBTCUpgrade(solvBtcProxy).isUpgradedToV2());

        uint256 totalSupplyAfter = SolvBTCUpgrade(solvBtcProxy).totalSupply();
        uint256 userBalanceAfter = SolvBTCUpgrade(solvBtcProxy).balanceOf(user);
        assertEq(totalSupplyBefore, totalSupplyAfter);
        assertEq(userBalanceBefore, userBalanceAfter);
    }

    function test_MintSolvBtcAfterUpgrade() public {
        _upgradeAndRecharge();
        deal(WBTC_ADDRESS, user, 10e8);

        vm.startPrank(user);        
        uint256 userWbtcBalanceBefore = ERC20(WBTC_ADDRESS).balanceOf(user);
        uint256 userSolvBtcBalanceBefore = ERC20(solvBtcProxy).balanceOf(user);
        uint256 vaultWbtcBalanceBefore = ERC20(WBTC_ADDRESS).balanceOf(solvBtcProxy);
        uint256 solvBtcTotalSupplyBefore = ERC20(solvBtcProxy).totalSupply();

        ERC20(WBTC_ADDRESS).approve(solvBtcProxy, 1e8);
        SolvBTCUpgrade(solvBtcProxy).deposit(1e8);

        uint256 userWbtcBalanceAfter = ERC20(WBTC_ADDRESS).balanceOf(user);
        uint256 userSolvBtcBalanceAfter = ERC20(solvBtcProxy).balanceOf(user);
        uint256 vaultWbtcBalanceAfter = ERC20(WBTC_ADDRESS).balanceOf(solvBtcProxy);
        uint256 solvBtcTotalSupplyAfter = ERC20(solvBtcProxy).totalSupply();

        assertEq(userWbtcBalanceBefore - userWbtcBalanceAfter, 1e8);
        assertEq(vaultWbtcBalanceAfter - vaultWbtcBalanceBefore, 1e8);
        assertEq(userSolvBtcBalanceAfter - userSolvBtcBalanceBefore, 1e18);
        assertEq(solvBtcTotalSupplyAfter - solvBtcTotalSupplyBefore, 1e18);
        vm.stopPrank();
    }

    function test_BurnSolvBtcAfterUpgrade() public {
        _upgradeAndRecharge();

        vm.startPrank(user);        
        uint256 userWbtcBalanceBefore = ERC20(WBTC_ADDRESS).balanceOf(user);
        uint256 userSolvBtcBalanceBefore = ERC20(solvBtcProxy).balanceOf(user);
        uint256 vaultWbtcBalanceBefore = ERC20(WBTC_ADDRESS).balanceOf(solvBtcProxy);
        uint256 solvBtcTotalSupplyBefore = ERC20(solvBtcProxy).totalSupply();

        uint256 burnSolvBtcAmount = userSolvBtcBalanceBefore / 3;
        uint256 burnWtcAmount = burnSolvBtcAmount * (10 ** ERC20(WBTC_ADDRESS).decimals()) / (10 ** ERC20(solvBtcProxy).decimals());
        SolvBTCUpgrade(solvBtcProxy).withdraw(burnSolvBtcAmount);

        uint256 userWbtcBalanceAfter = ERC20(WBTC_ADDRESS).balanceOf(user);
        uint256 userSolvBtcBalanceAfter = ERC20(solvBtcProxy).balanceOf(user);
        uint256 vaultWbtcBalanceAfter = ERC20(WBTC_ADDRESS).balanceOf(solvBtcProxy);
        uint256 solvBtcTotalSupplyAfter = ERC20(solvBtcProxy).totalSupply();

        assertEq(userWbtcBalanceAfter - userWbtcBalanceBefore, burnWtcAmount);
        assertEq(vaultWbtcBalanceBefore - vaultWbtcBalanceAfter, burnWtcAmount);
        assertEq(userSolvBtcBalanceBefore - userSolvBtcBalanceAfter, burnSolvBtcAmount);
        assertEq(solvBtcTotalSupplyBefore - solvBtcTotalSupplyAfter, burnSolvBtcAmount);
        vm.stopPrank();
    }

    function test_RevertWhenMintZeroAmount() public {
        _upgradeAndRecharge();
        deal(WBTC_ADDRESS, user, 10e8);

        vm.startPrank(user);        
        ERC20(WBTC_ADDRESS).approve(solvBtcProxy, 1e8);
        vm.expectRevert("SolvBTC: invalid amount");
        SolvBTCUpgrade(solvBtcProxy).deposit(0);
        vm.stopPrank();
    }

    function test_RevertWhenMintNotPassBalanceCheck() public {
        _upgradeAndRecharge();
        deal(WBTC_ADDRESS, user, 10e8);

        vm.startPrank(user);
        uint256 vaultWbtcBalance = ERC20(WBTC_ADDRESS).balanceOf(solvBtcProxy);
        vm.mockCall(WBTC_ADDRESS, abi.encodeWithSignature("balanceOf(address)", solvBtcProxy), abi.encode(vaultWbtcBalance - 1));
        ERC20(WBTC_ADDRESS).approve(solvBtcProxy, 1e8);
        vm.expectRevert("SolvBTC: balance check error");
        SolvBTCUpgrade(solvBtcProxy).deposit(1e8);
        vm.stopPrank();
    }

    function test_RevertWhenMintAfterUpgradeWithoutRecharge() public {
        _upgrade();
        deal(WBTC_ADDRESS, user, 10e8);

        vm.startPrank(user);
        ERC20(WBTC_ADDRESS).approve(solvBtcProxy, 1e8);
        vm.expectRevert("SolvBTC: balance check error");
        SolvBTCUpgrade(solvBtcProxy).deposit(1e8);
        vm.stopPrank();
    }

    function test_RevertWhenBurnZeroAmount() public {
        _upgradeAndRecharge();
        deal(WBTC_ADDRESS, user, 10e8);

        vm.startPrank(user);        
        ERC20(WBTC_ADDRESS).approve(solvBtcProxy, 1e8);
        SolvBTCUpgrade(solvBtcProxy).deposit(1e8);
        vm.expectRevert("SolvBTC: invalid amount");
        SolvBTCUpgrade(solvBtcProxy).withdraw(0);
        vm.stopPrank();
    }

    function test_RevertWhenBurnNotPassBalanceCheck() public {
        _upgradeAndRecharge();
        deal(WBTC_ADDRESS, user, 10e8);

        vm.startPrank(user);
        ERC20(WBTC_ADDRESS).approve(solvBtcProxy, 1e8);
        SolvBTCUpgrade(solvBtcProxy).deposit(1e8);

        uint256 vaultWbtcBalance = ERC20(WBTC_ADDRESS).balanceOf(solvBtcProxy);
        vm.mockCall(WBTC_ADDRESS, abi.encodeWithSignature("balanceOf(address)", solvBtcProxy), abi.encode(vaultWbtcBalance - 1));
        vm.expectRevert("SolvBTC: balance check error");
        SolvBTCUpgrade(solvBtcProxy).withdraw(1e8);
        vm.stopPrank();
    }

    function test_RevertWhenBurnAfterUpgradeWithoutRecharge() public {
        _upgrade();

        vm.startPrank(user);
        uint256 userSolvBtcBalance = ERC20(solvBtcProxy).balanceOf(user);
        deal(WBTC_ADDRESS, solvBtcProxy, userSolvBtcBalance * (10 ** ERC20(WBTC_ADDRESS).decimals()) / (10 ** ERC20(solvBtcProxy).decimals()));
        vm.expectRevert("SolvBTC: balance check error");
        SolvBTCUpgrade(solvBtcProxy).withdraw(userSolvBtcBalance);
        vm.stopPrank();
    }

    function test_RevertWhenUpgradeMoreThanOnce() public {
        _upgrade();
        vm.expectRevert("SolvBTC: already upgraded to v2");
        SolvBTCUpgrade(solvBtcProxy).upgradeToV2DoOnlyOnce();
    }


    function _upgradeAndRecharge() internal {
        _upgrade();
        _recharge();
    }

    function _upgrade() internal {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, solvBtcImpl_v2);
        factory.upgradeBeacon(PRODUCT_TYPE);
        assertEq(factory.getImplementation(PRODUCT_TYPE), solvBtcImpl_v2);
        assertEq(UpgradeableBeacon(solvBtcBeacon).implementation(), solvBtcImpl_v2);
        SolvBTCUpgrade(solvBtcProxy).upgradeToV2DoOnlyOnce();
        vm.stopPrank();
    }

    function _recharge() internal {
        vm.startPrank(admin);
        uint256 totalSupply = SolvBTCUpgrade(solvBtcProxy).totalSupply();
        uint256 wbtcAmount = totalSupply * (10 ** ERC20(WBTC_ADDRESS).decimals()) / (10 ** ERC20(solvBtcProxy).decimals());
        deal(WBTC_ADDRESS, admin, wbtcAmount);
        ERC20(WBTC_ADDRESS).transfer(solvBtcProxy, wbtcAmount);
        vm.stopPrank();
    }

}