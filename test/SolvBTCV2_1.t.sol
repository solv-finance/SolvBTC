// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCV2_1.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

/**
 * @title Test for SolvBTC V2.1 upgrade.
 * @notice Fork Arbitrum chain at block number 283200000 to run tests.
 */
contract SolvBTCV2_1Test is Test {
    string internal constant PRODUCT_TYPE = "Solv BTC";
    string internal constant PRODUCT_NAME = "Solv BTC";

    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCV2_1 internal solvBTCV2_1 = SolvBTCV2_1(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    address internal solvBTCBeacon = 0x3d209Fb3ca4fCBA1f43f3F14285e2307Db531C07;
    address internal solvBTCV2_1Impl;

    SolvBTCFactory internal solvBTCFactory = SolvBTCFactory(0x443628281E4f3E5b5A5D029B9a0D13900ae41578);

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    address internal OWNER = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal MINTER = 0xf00aa0442bD2abFA2Fe20B12a1f88104A61037c7;
    address internal USER_1 = 0x7E8bC7427f2a9464F22f578ce2a39521ABCF03C6;
    address internal USER_2 = 0xc1b03bc15Bd3E55fA8cC584E53003d43cB5B215c;

    uint256 internal totalSupplyBeforeUpgrade;
    uint8 internal decimalsBeforeUpgrade;
    uint256 internal user1BalanceBeforeUpgrade;
    uint256 internal user2BalanceBeforeUpgrade;

    function setUp() public {
        totalSupplyBeforeUpgrade = solvBTC.totalSupply();
        decimalsBeforeUpgrade = solvBTC.decimals();
        user1BalanceBeforeUpgrade = solvBTC.balanceOf(USER_1);
        user2BalanceBeforeUpgrade = solvBTC.balanceOf(USER_2);
        console.log("user1BalanceBeforeUpgrade: ", user1BalanceBeforeUpgrade);
        console.log("user2BalanceBeforeUpgrade: ", user2BalanceBeforeUpgrade);

        vm.startPrank(OWNER);
        solvBTCV2_1Impl = address(new SolvBTCV2_1());
        solvBTCFactory.setImplementation(PRODUCT_TYPE, solvBTCV2_1Impl);
        vm.stopPrank();
    }

    function test_FactoryStatus() public {
        assertEq(solvBTCFactory.getProxy(PRODUCT_TYPE, PRODUCT_NAME), address(solvBTCV2_1));
        assertEq(solvBTCFactory.getBeacon(PRODUCT_TYPE), solvBTCBeacon);
        assertEq(solvBTCFactory.getImplementation(PRODUCT_TYPE), solvBTCV2_1Impl);
    }

    function test_SolvBTCStatusAfterUpgrade() public {
        assertEq(solvBTCV2_1.totalSupply(), totalSupplyBeforeUpgrade);
        assertEq(solvBTCV2_1.decimals(), decimalsBeforeUpgrade);
        assertEq(solvBTCV2_1.balanceOf(USER_1), user1BalanceBeforeUpgrade);
        assertEq(solvBTCV2_1.balanceOf(USER_2), user2BalanceBeforeUpgrade);
        assertEq(solvBTCV2_1.owner(), OWNER);
        assertEq(solvBTCV2_1.hasRole(solvBTC.SOLVBTC_MINTER_ROLE(), MINTER), true);
    }

}