// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCV2.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

contract SolvBTCV2Test is Test {
    string internal constant PRODUCT_TYPE = "Solv BTC";
    string internal constant PRODUCT_NAME = "Solv BTC";

    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCV2 internal solvBTCV2;
    address internal solvBTCBeacon = 0x3d209Fb3ca4fCBA1f43f3F14285e2307Db531C07;
    address internal solvBTCV2Impl;

    SolvBTCFactory internal solvBTCFactory = SolvBTCFactory(0x443628281E4f3E5b5A5D029B9a0D13900ae41578);

    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    address internal OWNER = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal MINTER = 0xf00aa0442bD2abFA2Fe20B12a1f88104A61037c7;
    address internal USER_1 = 0x7E8bC7427f2a9464F22f578ce2a39521ABCF03C6;
    address internal USER_2 = 0xc1b03bc15Bd3E55fA8cC584E53003d43cB5B215c;
    address internal USER_3 = 0xa893D9618A61D150e69a3532E673bC2CE441dD31;
    address internal BLACKLIST_MANAGER = makeAddr("BLACKLIST_MANAGER");

    uint256 internal totalSupplyBeforeUpgrade;
    uint8 internal decimalsBeforeUpgrade;
    uint256 internal user1BalanceBeforeUpgrade;
    uint256 internal user2BalanceBeforeUpgrade;

    function setUp() public {
        totalSupplyBeforeUpgrade = solvBTC.totalSupply();
        decimalsBeforeUpgrade = solvBTC.decimals();
        user1BalanceBeforeUpgrade = solvBTC.balanceOf(USER_1);
        user2BalanceBeforeUpgrade = solvBTC.balanceOf(USER_2);

        vm.startPrank(OWNER);
        solvBTCV2Impl = address(new SolvBTCV2());
        solvBTCFactory.setImplementation(PRODUCT_TYPE, solvBTCV2Impl);
        solvBTCV2 = SolvBTCV2(address(solvBTC));

        solvBTCV2.updateBlacklistManager(BLACKLIST_MANAGER);
        vm.stopPrank();
    }

    function test_FactoryStatus() public {
        assertEq(solvBTCFactory.getProxy(PRODUCT_TYPE, PRODUCT_NAME), address(solvBTC));
        assertEq(solvBTCFactory.getBeacon(PRODUCT_TYPE), solvBTCBeacon);
        assertEq(solvBTCFactory.getImplementation(PRODUCT_TYPE), solvBTCV2Impl);
    }

    function test_SolvBTCStatusAfterUpgrade() public {
        assertEq(solvBTCV2.totalSupply(), totalSupplyBeforeUpgrade);
        assertEq(solvBTCV2.decimals(), decimalsBeforeUpgrade);
        assertEq(solvBTCV2.balanceOf(USER_1), user1BalanceBeforeUpgrade);
        assertEq(solvBTCV2.balanceOf(USER_2), user2BalanceBeforeUpgrade);
        assertEq(solvBTCV2.owner(), OWNER);
        assertEq(solvBTCV2.hasRole(solvBTC.SOLVBTC_MINTER_ROLE(), MINTER), true);
        assertEq(solvBTCV2.blacklistManager(), BLACKLIST_MANAGER);
    }

    function test_ApproveWhenBlacklisted() public {
        assertEq(solvBTCV2.isBlacklisted(USER_1), false);
        assertEq(solvBTCV2.isBlacklisted(USER_2), false);

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.addBlacklist(USER_1);
        vm.stopPrank();

        assertEq(solvBTCV2.isBlacklisted(USER_1), true);
        assertEq(solvBTCV2.isBlacklisted(USER_2), false);

        vm.startPrank(USER_1);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.approve(USER_1, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCV2.approve(USER_2, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.approve(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.removeBlacklist(USER_1);
        vm.stopPrank();

        assertEq(solvBTCV2.isBlacklisted(USER_1), false);
        assertEq(solvBTCV2.isBlacklisted(USER_2), false);

        vm.startPrank(USER_1);
        solvBTCV2.approve(USER_1, 100);
        solvBTCV2.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCV2.approve(USER_2, 100);
        solvBTCV2.approve(USER_1, 100);
        vm.stopPrank();

    }

    function test_TransferWhenBlacklisted() public {
        vm.startPrank(USER_1);
        solvBTCV2.approve(USER_1, type(uint256).max);
        vm.stopPrank();
        vm.startPrank(USER_2);
        solvBTCV2.approve(USER_2, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(USER_1);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.transfer(USER_2, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCV2.transfer(OWNER, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.transfer(USER_1, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.transferFrom(USER_2, USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(USER_1);
        solvBTCV2.transfer(USER_2, 100);
        solvBTCV2.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();
    }

    function test_MintWhenBlacklisted() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.mint(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        solvBTCV2.mint(USER_1, 100);
        vm.stopPrank();
    }

    function test_BurnWhenBlacklisted() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCV2.burn(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        solvBTCV2.burn(USER_1, 100);
        vm.stopPrank();
    }

    function test_UpdateBlacklistBatch() public {
        address[] memory addList = new address[](3);
        addList[0] = USER_1;
        addList[1] = USER_2;
        addList[2] = USER_3;

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.addBlacklistBatch(addList);
        vm.stopPrank();

        assertEq(solvBTCV2.isBlacklisted(USER_1), true);
        assertEq(solvBTCV2.isBlacklisted(USER_2), true);
        assertEq(solvBTCV2.isBlacklisted(USER_3), true);

        address[] memory removeList = new address[](2);
        removeList[0] = USER_1;
        removeList[1] = USER_2;

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.removeBlacklistBatch(removeList);
        vm.stopPrank();

        assertEq(solvBTCV2.isBlacklisted(USER_1), false);
        assertEq(solvBTCV2.isBlacklisted(USER_2), false);
        assertEq(solvBTCV2.isBlacklisted(USER_3), true);
    }

    function test_DestroyBlackFunds() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCV2.addBlacklist(USER_1);
        vm.stopPrank();

        uint256 user1BalanceBefore = solvBTCV2.balanceOf(USER_1);
        uint256 totalSupplyBefore = solvBTCV2.totalSupply();

        vm.startPrank(OWNER);
        solvBTCV2.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();

        assertEq(solvBTCV2.balanceOf(USER_1), user1BalanceBefore - 100);
        assertEq(solvBTCV2.totalSupply(), totalSupplyBefore - 100);
    }

    function test_RevertWhenDetroyBlackFundsByNonOwner() public {
        vm.startPrank(BLACKLIST_MANAGER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", BLACKLIST_MANAGER));
        solvBTCV2.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();
    }

    function test_RevertWhenDetroyFundsFromNonBlacklistedUser() public {
        vm.startPrank(OWNER);
        vm.expectRevert("SolvBTCV2: account is not blacklisted");
        solvBTCV2.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();
    }

    function test_RevertWhenUpdateManagerByNonOwner() public {
        vm.startPrank(BLACKLIST_MANAGER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", BLACKLIST_MANAGER));
        solvBTCV2.updateBlacklistManager(BLACKLIST_MANAGER);
        vm.stopPrank();
    }

    function test_RevertWhenSetBlacklistByNonManager() public {
        vm.startPrank(USER_1);
        vm.expectRevert("Blacklistable: caller is not the blacklist manager");
        solvBTCV2.addBlacklist(USER_1);
        vm.expectRevert("Blacklistable: caller is not the blacklist manager");
        solvBTCV2.removeBlacklist(USER_1);
        vm.stopPrank();
    }
}