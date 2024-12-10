// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTCYieldToken.sol";
import "../contracts/SolvBTCYieldTokenV2_1.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

/**
 * @title Test for SolvBTCYieldToken V2.1 upgrade.
 * @notice Fork Arbitrum chain at block number 283200000 to run tests.
 */
contract SolvBTCYieldTokenV2Test is Test {
    string internal constant PRODUCT_TYPE = "SolvBTC Yield Token";
    string internal constant PRODUCT_NAME = "SolvBTC Babylon";

    SolvBTCYieldToken internal solvBTCYieldToken = SolvBTCYieldToken(0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB);
    SolvBTCYieldTokenV2_1 internal solvBTCYieldTokenV2_1 = SolvBTCYieldTokenV2_1(0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB);
    address internal solvBTCYieldTokenBeacon = 0x7B375C1a95335Ec443f9b610b427e5AfC91E566D;
    address internal solvBTCYieldTokenV2_1Impl;

    SolvBTCFactory internal solvBTCYieldTokenFactory = SolvBTCFactory(0x7DF05aD635456a07ae77Eb5468cA7d0b44687271);

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    address internal OWNER = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal MINTER = 0x0679E96f5EEDa5313099f812b558714717AEC176;
    address internal USER_1 = 0x3D64cFEEf2B66AdD5191c387E711AF47ab01e296;
    address internal USER_2 = 0x291c6DFDECCbc3e15486eC859faBA8B075794d59;
    address internal USER_3 = 0x091D23De14E6cC4b8Bbd4eEeb17cd71A68dF8Bee;
    address internal BLACKLIST_MANAGER = makeAddr("BLACKLIST_MANAGER");

    uint256 internal totalSupplyBeforeUpgrade;
    uint8 internal decimalsBeforeUpgrade;
    uint256 internal user1BalanceBeforeUpgrade;
    uint256 internal user2BalanceBeforeUpgrade;

    function setUp() public {
        totalSupplyBeforeUpgrade = solvBTCYieldToken.totalSupply();
        decimalsBeforeUpgrade = solvBTCYieldToken.decimals();
        user1BalanceBeforeUpgrade = solvBTCYieldToken.balanceOf(USER_1);
        user2BalanceBeforeUpgrade = solvBTCYieldToken.balanceOf(USER_2);

        vm.startPrank(OWNER);
        solvBTCYieldTokenV2_1Impl = address(new SolvBTCYieldTokenV2_1());
        solvBTCYieldTokenFactory.setImplementation(PRODUCT_TYPE, solvBTCYieldTokenV2_1Impl);
        vm.stopPrank();
    }

    function test_FactoryStatus() public {
        assertEq(solvBTCYieldTokenFactory.getProxy(PRODUCT_TYPE, PRODUCT_NAME), address(solvBTCYieldToken));
        assertEq(solvBTCYieldTokenFactory.getBeacon(PRODUCT_TYPE), solvBTCYieldTokenBeacon);
        assertEq(solvBTCYieldTokenFactory.getImplementation(PRODUCT_TYPE), solvBTCYieldTokenV2_1Impl);
    }

    function test_SolvBTCStatusAfterUpgrade() public {
        assertEq(solvBTCYieldTokenV2_1.totalSupply(), totalSupplyBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2_1.decimals(), decimalsBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2_1.balanceOf(USER_1), user1BalanceBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2_1.balanceOf(USER_2), user2BalanceBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2_1.owner(), OWNER);
        assertEq(solvBTCYieldTokenV2_1.hasRole(solvBTCYieldToken.SOLVBTC_MINTER_ROLE(), MINTER), true);
        assertEq(solvBTCYieldTokenV2_1.getOracle(), 0x94e768B546f2580f2B47249F278e554ff8a9077e);
    }

}