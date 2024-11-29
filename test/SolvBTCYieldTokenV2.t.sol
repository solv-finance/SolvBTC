// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTCYieldToken.sol";
import "../contracts/SolvBTCYieldTokenV2.sol";

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";

contract SolvBTCYieldTokenV2Test is Test {
    string internal constant PRODUCT_TYPE = "SolvBTC Yield Token";
    string internal constant PRODUCT_NAME = "SolvBTC Babylon";

    SolvBTCYieldToken internal solvBTCYieldToken = SolvBTCYieldToken(0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB);
    SolvBTCYieldTokenV2 internal solvBTCYieldTokenV2;
    address internal solvBTCYieldTokenBeacon = 0x7B375C1a95335Ec443f9b610b427e5AfC91E566D;
    address internal solvBTCYieldTokenV2Impl;

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
        solvBTCYieldTokenV2Impl = address(new SolvBTCYieldTokenV2());
        solvBTCYieldTokenFactory.setImplementation(PRODUCT_TYPE, solvBTCYieldTokenV2Impl);
        solvBTCYieldTokenV2 = SolvBTCYieldTokenV2(address(solvBTCYieldToken));

        solvBTCYieldTokenV2.updateBlacklistManager(BLACKLIST_MANAGER);
        vm.stopPrank();
    }

    function test_FactoryStatus() public {
        assertEq(solvBTCYieldTokenFactory.getProxy(PRODUCT_TYPE, PRODUCT_NAME), address(solvBTCYieldToken));
        assertEq(solvBTCYieldTokenFactory.getBeacon(PRODUCT_TYPE), solvBTCYieldTokenBeacon);
        assertEq(solvBTCYieldTokenFactory.getImplementation(PRODUCT_TYPE), solvBTCYieldTokenV2Impl);
    }

    function test_SolvBTCStatusAfterUpgrade() public {
        assertEq(solvBTCYieldTokenV2.totalSupply(), totalSupplyBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2.decimals(), decimalsBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2.balanceOf(USER_1), user1BalanceBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2.balanceOf(USER_2), user2BalanceBeforeUpgrade);
        assertEq(solvBTCYieldTokenV2.owner(), OWNER);
        assertEq(solvBTCYieldTokenV2.hasRole(solvBTCYieldToken.SOLVBTC_MINTER_ROLE(), MINTER), true);
        assertEq(solvBTCYieldTokenV2.blacklistManager(), BLACKLIST_MANAGER);
    }

    function test_ApproveWhenBlacklisted() public {
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_1), false);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_2), false);

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.addBlacklist(USER_1);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_1), true);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_2), false);

        vm.startPrank(USER_1);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.approve(USER_1, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV2.approve(USER_2, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.approve(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.removeBlacklist(USER_1);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_1), false);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_2), false);

        vm.startPrank(USER_1);
        solvBTCYieldTokenV2.approve(USER_1, 100);
        solvBTCYieldTokenV2.approve(USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV2.approve(USER_2, 100);
        solvBTCYieldTokenV2.approve(USER_1, 100);
        vm.stopPrank();

    }

    function test_TransferWhenBlacklisted() public {
        vm.startPrank(USER_1);
        solvBTCYieldTokenV2.approve(USER_1, type(uint256).max);
        vm.stopPrank();
        vm.startPrank(USER_2);
        solvBTCYieldTokenV2.approve(USER_2, type(uint256).max);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(USER_1);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.transfer(USER_2, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();

        vm.startPrank(USER_2);
        solvBTCYieldTokenV2.transfer(OWNER, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.transfer(USER_1, 100);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.transferFrom(USER_2, USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(USER_1);
        solvBTCYieldTokenV2.transfer(USER_2, 100);
        solvBTCYieldTokenV2.transferFrom(USER_1, USER_2, 100);
        vm.stopPrank();
    }

    function test_MintWhenBlacklisted() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.mint(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        solvBTCYieldTokenV2.mint(USER_1, 100);
        vm.stopPrank();
    }

    function test_BurnWhenBlacklisted() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.addBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        vm.expectRevert("Blacklistable: account is blacklisted");
        solvBTCYieldTokenV2.burn(USER_1, 100);
        vm.stopPrank();

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.removeBlacklist(USER_1);
        vm.stopPrank();

        vm.startPrank(MINTER);
        solvBTCYieldTokenV2.burn(USER_1, 100);
        vm.stopPrank();
    }

    function test_UpdateBlacklistBatch() public {
        address[] memory addList = new address[](3);
        addList[0] = USER_1;
        addList[1] = USER_2;
        addList[2] = USER_3;

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.addBlacklistBatch(addList);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_1), true);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_2), true);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_3), true);

        address[] memory removeList = new address[](2);
        removeList[0] = USER_1;
        removeList[1] = USER_2;

        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.removeBlacklistBatch(removeList);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_1), false);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_2), false);
        assertEq(solvBTCYieldTokenV2.isBlacklisted(USER_3), true);
    }

    function test_DestroyBlackFunds() public {
        vm.startPrank(BLACKLIST_MANAGER);
        solvBTCYieldTokenV2.addBlacklist(USER_1);
        vm.stopPrank();

        uint256 user1BalanceBefore = solvBTCYieldTokenV2.balanceOf(USER_1);
        uint256 totalSupplyBefore = solvBTCYieldTokenV2.totalSupply();

        vm.startPrank(OWNER);
        solvBTCYieldTokenV2.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();

        assertEq(solvBTCYieldTokenV2.balanceOf(USER_1), user1BalanceBefore - 100);
        assertEq(solvBTCYieldTokenV2.totalSupply(), totalSupplyBefore - 100);
    }

    function test_RevertWhenDetroyBlackFundsByNonOwner() public {
        vm.startPrank(BLACKLIST_MANAGER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", BLACKLIST_MANAGER));
        solvBTCYieldTokenV2.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();
    }

    function test_RevertWhenDetroyFundsFromNonBlacklistedUser() public {
        vm.startPrank(OWNER);
        vm.expectRevert("SolvBTCV2: account is not blacklisted");
        solvBTCYieldTokenV2.destroyBlackFunds(USER_1, 100);
        vm.stopPrank();
    }

    function test_RevertWhenUpdateManagerByNonOwner() public {
        vm.startPrank(BLACKLIST_MANAGER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", BLACKLIST_MANAGER));
        solvBTCYieldTokenV2.updateBlacklistManager(BLACKLIST_MANAGER);
        vm.stopPrank();
    }

    function test_RevertWhenSetBlacklistByNonManager() public {
        vm.startPrank(USER_1);
        vm.expectRevert("Blacklistable: caller is not the blacklist manager");
        solvBTCYieldTokenV2.addBlacklist(USER_1);
        vm.expectRevert("Blacklistable: caller is not the blacklist manager");
        solvBTCYieldTokenV2.removeBlacklist(USER_1);
        vm.stopPrank();
    }
}