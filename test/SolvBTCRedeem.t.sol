// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/SolvBTCRedeem.sol";
import "../lib/forge-std/src/Test.sol";

contract SolvBTCRedeemTest is Test {

    ERC20 internal WBTC = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    SolvBTC internal SOLVBTC = SolvBTC(0x7A56E1C57C7475CCf742a1832B028F0456652F97);
    SolvBTCRedeem internal solvbtcRedeem;

    address internal ADMIN = 0xfd4B809AD88db6Ca9dbB295A4B9d23bB0093f497;
    address internal REDEMPTION_VAULT = 0x9Bc8EF6bb09e3D0F3F3a6CD02D2B9dC3115C7c5C;

    address internal FEE_RECIPIENT = makeAddr("fee recipient");
    address internal CALLER = makeAddr("caller");
    address internal USER = makeAddr("user");

    function setUp() public {
        SolvBTCRedeem implementation = new SolvBTCRedeem();
        bytes memory initData = abi.encodeCall(
            SolvBTCRedeem.initialize, (ADMIN, REDEMPTION_VAULT, address(WBTC), address(SOLVBTC), FEE_RECIPIENT, false)
        );
        solvbtcRedeem = SolvBTCRedeem(address(new ERC1967Proxy(address(implementation), initData)));

        vm.startPrank(ADMIN);
        SOLVBTC.grantRole(SOLVBTC.SOLVBTC_POOL_BURNER_ROLE(), address(solvbtcRedeem));

        deal(address(WBTC), REDEMPTION_VAULT, 10e8);
        deal(address(SOLVBTC), CALLER, 20 ether);

        vm.startPrank(REDEMPTION_VAULT);
        WBTC.approve(address(solvbtcRedeem), 10e8);
        vm.stopPrank();
    }

    function testWithdrawTransfersValueAndFee() public {
        uint256 amount = 0.05 ether;
        vm.prank(ADMIN);
        solvbtcRedeem.setWithdrawFeeRate(100); // 1%

        uint256 vault_SolvBTC_before = SOLVBTC.balanceOf(REDEMPTION_VAULT);
        uint256 vault_WBTC_before = WBTC.balanceOf(REDEMPTION_VAULT);
        uint256 feeRecipient_SolvBTC_before = SOLVBTC.balanceOf(FEE_RECIPIENT);
        uint256 feeRecipient_WBTC_before = WBTC.balanceOf(FEE_RECIPIENT);
        uint256 caller_SolvBTC_before = SOLVBTC.balanceOf(CALLER);
        uint256 caller_WBTC_before = WBTC.balanceOf(CALLER);
        uint256 user_SolvBTC_before = SOLVBTC.balanceOf(USER);
        uint256 user_WBTC_before = WBTC.balanceOf(USER);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        uint256 received = solvbtcRedeem.withdrawSolvBTC(USER, amount);

        uint256 expectedGross = 0.05e8;
        uint256 expectedFee = expectedGross / 100;
        uint256 expectedNet = expectedGross - expectedFee;

        assertEq(received, expectedNet, "received amount mismatch");
        assertEq(SOLVBTC.balanceOf(REDEMPTION_VAULT), vault_SolvBTC_before, "vault SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(REDEMPTION_VAULT), vault_WBTC_before - expectedGross, "vault WBTC balance mismatch");
        assertEq(SOLVBTC.balanceOf(FEE_RECIPIENT), feeRecipient_SolvBTC_before, "fee recipient SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(FEE_RECIPIENT), feeRecipient_WBTC_before + expectedFee, "fee recipient WBTC balance mismatch");
        assertEq(SOLVBTC.balanceOf(CALLER), caller_SolvBTC_before - amount, "caller SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(CALLER), caller_WBTC_before, "caller WBTC balance mismatch");
        assertEq(SOLVBTC.balanceOf(USER), user_SolvBTC_before, "user SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + expectedNet, "user WBTC balance mismatch");

        SolvBTCRedeem.RateLimit memory info = solvbtcRedeem.rateLimit();
        assertEq(info.amountWithdrawn, amount, "rate limit not updated");
        assertEq(info.lastWithdrawnAt, block.timestamp, "timestamp not refreshed");
    }

    function testSetMaxWindowWithdrawAmountClampsCurrentUsage() public {
        uint256 initialWithdraw = 0.08 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), initialWithdraw);
        solvbtcRedeem.withdrawSolvBTC(USER, initialWithdraw);

        uint256 newLimit = initialWithdraw / 4;
        uint256 newWindow = 1 hours;
        vm.startPrank(ADMIN);
        solvbtcRedeem.setMaxWindowWithdrawAmount(newLimit, newWindow);
        vm.stopPrank();

        SolvBTCRedeem.RateLimit memory info = solvbtcRedeem.rateLimit();
        assertEq(info.amountWithdrawn, newLimit, "clamp failed");
        assertEq(info.maxWindowWithdrawAmount, newLimit, "limit not updated");
        assertEq(info.window, newWindow, "window not updated");
    }

    function testWithdrawRespectsRateLimits() public {
        uint256 singleLimit = 0.1 ether;
        vm.startPrank(ADMIN);
        solvbtcRedeem.setMaxSingleWithdrawAmount(singleLimit);

        uint256 newWindow = 1 days;
        uint256 windowLimit = singleLimit * 2;
        solvbtcRedeem.setMaxWindowWithdrawAmount(windowLimit, newWindow);
        vm.stopPrank();

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), singleLimit * 3);

        solvbtcRedeem.withdrawSolvBTC(USER, singleLimit);
        solvbtcRedeem.withdrawSolvBTC(USER, singleLimit);

        vm.expectRevert("SolvBTCRedeem: amount exceeds daily withdraw amount");
        solvbtcRedeem.withdrawSolvBTC(USER, 1);

        vm.warp(block.timestamp + newWindow);

        solvbtcRedeem.withdrawSolvBTC(USER, singleLimit);
    }

    function testWithdrawZeroAmountReverts() public {
        vm.prank(CALLER);
        vm.expectRevert("SolvBTCRedeem: amount cannot be 0");
        solvbtcRedeem.withdrawSolvBTC(USER, 0);
    }

    function testWithdrawAtMaxSingleLimitBoundary() public {
        uint256 limit = 0.02 ether;
        vm.prank(ADMIN);
        solvbtcRedeem.setMaxSingleWithdrawAmount(limit);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), limit);
        solvbtcRedeem.withdrawSolvBTC(USER, limit);

        vm.expectRevert("SolvBTCRedeem: amount exceeds single withdraw amount");
        solvbtcRedeem.withdrawSolvBTC(USER, limit + 1);
    }

    function testSetMaxSingleWithdrawAmountOnlyAdmin() public {
        uint256 newLimit = 2e16;
        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.setMaxSingleWithdrawAmount(newLimit);

        vm.prank(ADMIN);
        solvbtcRedeem.setMaxSingleWithdrawAmount(newLimit);
        SolvBTCRedeem.RateLimit memory info = solvbtcRedeem.rateLimit();
        assertEq(info.maxSingleWithdrawAmount, newLimit, "max single withdraw amount not updated");
    }

    function testSetMaxWindowWithdrawAmountValidations() public {
        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.setMaxWindowWithdrawAmount(1 ether, 1 days);

        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCRedeem: window cannot be 0");
        solvbtcRedeem.setMaxWindowWithdrawAmount(1 ether, 0);

        uint256 newLimit = 3e17;
        uint256 newWindow = 2 days;
        solvbtcRedeem.setMaxWindowWithdrawAmount(newLimit, newWindow);
        SolvBTCRedeem.RateLimit memory info = solvbtcRedeem.rateLimit();
        assertEq(info.maxWindowWithdrawAmount, newLimit, "max window withdraw amount not updated");
        assertEq(info.window, newWindow, "window not updated");
    }

    function testSetWithdrawFeeRateOnlyAdmin() public {
        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.setWithdrawFeeRate(100);

        uint64 newFeeRate = 250;
        vm.prank(ADMIN);
        solvbtcRedeem.setWithdrawFeeRate(newFeeRate);
        assertEq(solvbtcRedeem.withdrawFeeRate(), newFeeRate, "withdraw fee rate not updated");
    }

    function testSetFeeRecipientRequiresAdminAndNonZero() public {
        address newFeeRecipient = makeAddr("newFeeRecipient");

        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.setFeeRecipient(newFeeRecipient);

        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCRedeem: fee recipient cannot be 0 address");
        solvbtcRedeem.setFeeRecipient(address(0));

        solvbtcRedeem.setWithdrawFeeRate(100); // 1%
        solvbtcRedeem.setFeeRecipient(newFeeRecipient);
        vm.stopPrank();

        uint256 feeBalanceBefore = SOLVBTC.balanceOf(newFeeRecipient);
        uint256 amount = 0.05 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        solvbtcRedeem.withdrawSolvBTC(USER, amount);
        assertEq(WBTC.balanceOf(newFeeRecipient) - feeBalanceBefore, 0.05e8 / 100, "fee recipient should receive withdraw fee");
    }

    function testSetRedemptionVaultRequiresAdminAndNonZero() public {
        address oldVault = REDEMPTION_VAULT;
        address newVault = makeAddr("newRedemptionVault");

        deal(address(WBTC), newVault, 10e8);
        vm.prank(newVault);
        WBTC.approve(address(solvbtcRedeem), 10e8);

        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.setRedemptionVault(newVault);

        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCRedeem: redemption vault cannot be 0 address");
        solvbtcRedeem.setRedemptionVault(address(0));

        solvbtcRedeem.setRedemptionVault(newVault);
        vm.stopPrank();

        uint256 amount = 0.005 ether;
        uint256 oldVaultBalanceBefore = WBTC.balanceOf(oldVault);
        uint256 newVaultBalanceBefore = WBTC.balanceOf(newVault);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        solvbtcRedeem.withdrawSolvBTC(USER, amount);

        assertEq(WBTC.balanceOf(oldVault), oldVaultBalanceBefore, "old redemption vault should remain untouched");
        assertEq(newVaultBalanceBefore - WBTC.balanceOf(newVault), 0.005e8, "new redemption vault should supply solvBTC");
    }

    function testSetCurrencyRequiresAdminAndNonZero() public {
        address tBTC = 0x18084fbA666a33d37592fA2633fD49a74DD93a88;
        deal(tBTC, REDEMPTION_VAULT, 100 ether);

        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.setCurrency(tBTC);

        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTCRedeem: currency cannot be 0 address");
        solvbtcRedeem.setCurrency(address(0));

        solvbtcRedeem.setCurrency(tBTC);    
        vm.stopPrank();

        assertEq(solvbtcRedeem.currency(), tBTC, "currency not updated");

        vm.prank(REDEMPTION_VAULT);
        ERC20(tBTC).approve(address(solvbtcRedeem), 100 ether);

        uint256 amount = 0.1 ether;
        uint256 vault_WBTC_before = WBTC.balanceOf(REDEMPTION_VAULT);
        uint256 vault_tBTC_before = ERC20(tBTC).balanceOf(REDEMPTION_VAULT);
        uint256 user_WBTC_before = WBTC.balanceOf(USER);
        uint256 user_tBTC_before = ERC20(tBTC).balanceOf(USER);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        solvbtcRedeem.withdrawSolvBTC(USER, amount);

        assertEq(WBTC.balanceOf(REDEMPTION_VAULT), vault_WBTC_before, "vault WBTC balance mismatch");
        assertEq(vault_tBTC_before - ERC20(tBTC).balanceOf(REDEMPTION_VAULT), amount, "vault tBTC balance mismatch");
        assertEq(WBTC.balanceOf(USER), user_WBTC_before, "user WBTC balance mismatch");
        assertEq(ERC20(tBTC).balanceOf(USER) - user_tBTC_before, amount, "user tBTC balance mismatch");
    }

    function testPause() public {
        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.pause();

        vm.prank(ADMIN);
        solvbtcRedeem.pause();
        assertEq(solvbtcRedeem.paused(), true, "contract should be paused");

        uint256 amount = 0.05 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        solvbtcRedeem.withdrawSolvBTC(USER, amount);
        vm.stopPrank();

        vm.prank(USER);
        vm.expectRevert("only admin");
        solvbtcRedeem.unpause();

        vm.prank(ADMIN);
        solvbtcRedeem.unpause();
        assertEq(solvbtcRedeem.paused(), false, "contract should be unpaused");

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        solvbtcRedeem.withdrawSolvBTC(USER, amount);
    }

    function testWithdrawWithCallerRestriction() public {
        vm.prank(ADMIN);
        solvbtcRedeem.setCallerRestricted(true);

        uint256 amount = 0.05 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        vm.expectRevert("SolvBTCRedeem: caller not allowed");
        solvbtcRedeem.withdrawSolvBTC(USER, amount);
        vm.stopPrank();

        vm.prank(ADMIN);
        solvbtcRedeem.setCallerAllowed(CALLER, true);

        uint256 user_WBTC_before = WBTC.balanceOf(USER);
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        solvbtcRedeem.withdrawSolvBTC(USER, amount);
        vm.stopPrank();
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + 0.05e8, "user WBTC balance mismatch");

        vm.prank(ADMIN);
        solvbtcRedeem.setCallerAllowed(CALLER, false);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcRedeem), amount);
        vm.expectRevert("SolvBTCRedeem: caller not allowed");
        solvbtcRedeem.withdrawSolvBTC(USER, amount);
        vm.stopPrank();
    }
}
