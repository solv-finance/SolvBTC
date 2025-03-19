// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTCYieldToken.sol";
import "../contracts/SolvBTCYieldTokenV3.sol";
import "../contracts/SolvBTCYieldTokenV3_1.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

/**
 * @title Test for SolvBTCYieldToken V3.1 upgrade.
 * @notice Fork Arbitrum chain at block number 314160000 to run tests.
 */
contract SolvBTCYieldTokenV3_1Test is Test {
    string internal constant PRODUCT_TYPE = "SolvBTC Yield Token";
    string internal constant PRODUCT_NAME = "SolvBTC Babylon";

    SolvBTCYieldTokenV3 internal solvBTCYieldToken = SolvBTCYieldTokenV3(0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB);
    SolvBTCYieldTokenV3_1 internal solvBTCYieldTokenV3_1 =
        SolvBTCYieldTokenV3_1(0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB);
    address internal solvBTCYieldTokenBeacon = 0x7B375C1a95335Ec443f9b610b427e5AfC91E566D;
    address internal solvBTCYieldTokenV3_1Impl;

    SolvBTCFactory internal solvBTCYieldTokenFactory = SolvBTCFactory(0x7DF05aD635456a07ae77Eb5468cA7d0b44687271);

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    address internal OWNER = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal PAUSER = makeAddr("PAUSER");
    address internal MINTER = 0x0679E96f5EEDa5313099f812b558714717AEC176;
    address internal USER_1 = 0x3D64cFEEf2B66AdD5191c387E711AF47ab01e296;
    address internal USER_2 = 0xEE88442E9D2D3764ac7Ab60B618CD73cd9a5fA51;
    address internal USER_3 = 0x091D23De14E6cC4b8Bbd4eEeb17cd71A68dF8Bee;
    address internal BLACKLIST_MANAGER = makeAddr("BLACKLIST_MANAGER");

    uint256 internal totalSupplyBeforeUpgrade;
    uint8 internal decimalsBeforeUpgrade;
    uint256 internal user1BalanceBeforeUpgrade;
    uint256 internal user2BalanceBeforeUpgrade;

    function setUp() public {
        totalSupplyBeforeUpgrade = solvBTCYieldTokenV3_1.totalSupply();
        decimalsBeforeUpgrade = solvBTCYieldTokenV3_1.decimals();
        user1BalanceBeforeUpgrade = solvBTCYieldTokenV3_1.balanceOf(USER_1);
        user2BalanceBeforeUpgrade = solvBTCYieldTokenV3_1.balanceOf(USER_2);

        vm.startPrank(OWNER);
        solvBTCYieldTokenV3_1Impl = address(new SolvBTCYieldTokenV3_1());
        solvBTCYieldTokenFactory.setImplementation(PRODUCT_TYPE, solvBTCYieldTokenV3_1Impl);

        solvBTCYieldTokenV3_1.updateBlacklistManager(BLACKLIST_MANAGER);
        vm.stopPrank();
    }

    function test_FactoryStatus() public {
        assertEq(solvBTCYieldTokenFactory.getProxy(PRODUCT_TYPE, PRODUCT_NAME), address(solvBTCYieldToken));
        assertEq(solvBTCYieldTokenFactory.getBeacon(PRODUCT_TYPE), solvBTCYieldTokenBeacon);
        assertEq(solvBTCYieldTokenFactory.getImplementation(PRODUCT_TYPE), solvBTCYieldTokenV3_1Impl);
    }

    function test_SolvBTCStatusAfterUpgrade() public {
        assertEq(solvBTCYieldTokenV3_1.totalSupply(), totalSupplyBeforeUpgrade);
        assertEq(solvBTCYieldTokenV3_1.decimals(), decimalsBeforeUpgrade);
        assertEq(solvBTCYieldTokenV3_1.balanceOf(USER_1), user1BalanceBeforeUpgrade);
        assertEq(solvBTCYieldTokenV3_1.balanceOf(USER_2), user2BalanceBeforeUpgrade);
        assertEq(solvBTCYieldTokenV3_1.owner(), OWNER);
        assertEq(solvBTCYieldTokenV3_1.hasRole(solvBTCYieldToken.SOLVBTC_MINTER_ROLE(), MINTER), true);
        assertEq(solvBTCYieldTokenV3_1.blacklistManager(), BLACKLIST_MANAGER);
        assertEq(solvBTCYieldTokenV3_1.paused(), false);
    }

    /**
     * Blacklistable tests for V3
     */
    function test_ApproveWhenBlacklisted() public {
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_1), false);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_2), false);

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.addBlacklist(USER_1);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_1), true);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_2), false);

        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.approve(USER_1, 100);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV3_1.approve(USER_2, 100);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.approve(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.removeBlacklist(USER_1);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_1), false);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_2), false);

        vm.startPrank(USER_1);
        solvBTCYieldTokenV3_1.approve(USER_1, 100);
        solvBTCYieldTokenV3_1.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV3_1.approve(USER_2, 100);
        solvBTCYieldTokenV3_1.approve(USER_1, 100);
        vm.stopPrank();
    }

    function test_TransferWhenBlacklisted() public {
        vm.startPrank(USER_1);
        solvBTCYieldTokenV3_1.approve(USER_1, type(uint256).max);
        vm.stopPrank();
        vm.startPrank(USER_2);
        solvBTCYieldTokenV3_1.approve(USER_2, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.transfer(USER_2, 100);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV3_1.transfer(OWNER, 100);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.transfer(USER_1, 100);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.transferFrom(USER_2, USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(USER_1);
        solvBTCYieldTokenV3_1.transfer(USER_2, 100);
        solvBTCYieldTokenV3_1.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();
    }

    function test_MintWhenBlacklisted() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.mint(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        solvBTCYieldTokenV3_1.mint(USER_1, 100);
        vm.stopPrank();
    }

    function test_BurnWhenBlacklisted() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableBlacklistedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.burn(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        solvBTCYieldTokenV3_1.burn(USER_1, 100);
        vm.stopPrank();
    }

    function test_UpdateBlacklistBatch() public {
        address[] memory addList = new address[](3);
        addList[0] = USER_1;
        addList[1] = USER_2;
        addList[2] = USER_3;

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.addBlacklistBatch(addList);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_1), true);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_2), true);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_3), true);

        address[] memory removeList = new address[](2);
        removeList[0] = USER_1;
        removeList[1] = USER_2;

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.removeBlacklistBatch(removeList);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_1), false);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_2), false);
        assertEq(solvBTCYieldTokenV3_1.isBlacklisted(USER_3), true);
    }

    function test_DestroyBlackFunds() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV3_1.addBlacklist(USER_1);
        vm.stopPrank();

        uint256 user1BalanceBefore = solvBTCYieldTokenV3_1.balanceOf(USER_1);
        uint256 totalSupplyBefore = solvBTCYieldTokenV3_1.totalSupply();

        vm.startPrank(OWNER);
        solvBTCYieldTokenV3_1.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.balanceOf(USER_1), user1BalanceBefore - 100);
        assertEq(solvBTCYieldTokenV3_1.totalSupply(), totalSupplyBefore - 100);
    }

    function test_RevertWhenDetroyBlackFundsByNonOwner() public {
        vm.startPrank(BLACKLIST_MANAGER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", BLACKLIST_MANAGER));
        solvBTCYieldTokenV3_1.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();
    }

    function test_RevertWhenDetroyFundsFromNonBlacklistedUser() public {
        vm.startPrank(OWNER);
        vm.expectRevert(abi.encodeWithSignature("SolvBTCNotBlacklisted(address)", USER_1));
        solvBTCYieldTokenV3_1.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();
    }

    function test_RevertWhenUpdateManagerByNonOwner() public {
        vm.startPrank(BLACKLIST_MANAGER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", BLACKLIST_MANAGER));
        solvBTCYieldTokenV3_1.updateBlacklistManager(BLACKLIST_MANAGER);
        vm.stopPrank();
    }

    function test_RevertWhenSetBlacklistByNonManager() public {
        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableNotManager(address)", USER_1));
        solvBTCYieldTokenV3_1.addBlacklist(USER_1);
        vm.expectRevert(abi.encodeWithSignature("BlacklistableNotManager(address)", USER_1));
        solvBTCYieldTokenV3_1.removeBlacklist(USER_1);
        vm.stopPrank();
    }

    /**
     * Pausable tests for V3.1
     */
    function test_Pause1() public {
        vm.startPrank(OWNER);
        solvBTCYieldTokenV3_1.setPauser(PAUSER);
        vm.stopPrank();

        vm.startPrank(PAUSER);
        solvBTCYieldTokenV3_1.pause();
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.paused(), true);

        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        solvBTCYieldTokenV3_1.transfer(USER_2, 100);

        solvBTCYieldTokenV3_1.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        solvBTCYieldTokenV3_1.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();
    }

    function test_Unpause() public {
        vm.startPrank(OWNER);
        solvBTCYieldTokenV3_1.setPauser(PAUSER);
        vm.stopPrank();

        vm.startPrank(PAUSER);
        solvBTCYieldTokenV3_1.pause();
        vm.stopPrank();

        vm.startPrank(PAUSER);
        solvBTCYieldTokenV3_1.unpause();
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV3_1.paused(), false);

        vm.startPrank(USER_1);
        solvBTCYieldTokenV3_1.transfer(USER_2, 100);
        solvBTCYieldTokenV3_1.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV3_1.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();
    }

    function test_TransferWhenNotPaused() public {
        vm.startPrank(USER_1);
        solvBTCYieldTokenV3_1.transfer(USER_2, 100);
        vm.stopPrank();
    }

    function test_SetPauseByNonPauser() public {
        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("PausablePauser(address)", USER_1));
        solvBTCYieldTokenV3_1.pause();
        vm.expectRevert(abi.encodeWithSignature("PausablePauser(address)", USER_1));
        solvBTCYieldTokenV3_1.unpause();
        vm.stopPrank();
    }

    function test_setPauserByNonOwner() public {
        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.setPauser(USER_1);
        vm.stopPrank();
    }

    /**
     * Tests for not set name and symbol
     */
    function test_NotSetAlias() public {
        assertEq(solvBTCYieldTokenV3_1.name(), "SolvBTC Babylon");
        assertEq(solvBTCYieldTokenV3_1.symbol(), "SolvBTC.BBN");
    }

    /**
     * Tests for alias name and symbol
     */
    function test_SetAlias() public {
        vm.startPrank(OWNER);
        solvBTCYieldTokenV3_1.setAlias("x SolvBTC", "xSolvBTC");
        vm.stopPrank();
        assertEq(solvBTCYieldTokenV3_1.name(), "x SolvBTC");
        assertEq(solvBTCYieldTokenV3_1.symbol(), "xSolvBTC");
    }

    function test_SetAliasByNonOwner() public {
        vm.startPrank(USER_1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER_1));
        solvBTCYieldTokenV3_1.setAlias("x SolvBTC", "xSolvBTC");
        vm.stopPrank();
    }
}
