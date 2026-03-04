// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../contracts/SolvBTCWhitelistedSwap.sol";
import "../lib/forge-std/src/Test.sol";

contract SolvBTCWhitelistedSwapTest is Test {

    ERC20 internal WBTC = ERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
    SolvBTC internal SOLVBTC = SolvBTC(0x7A56E1C57C7475CCf742a1832B028F0456652F97);
    SolvBTCWhitelistedSwap internal solvbtcWhitelistedSwap;

    address internal GOVERNOR = 0xfd4B809AD88db6Ca9dbB295A4B9d23bB0093f497;
    address internal PAUSE_ADMIN = 0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D;
    address internal CURRENCY_VAULT = 0x9Bc8EF6bb09e3D0F3F3a6CD02D2B9dC3115C7c5C;

    address internal FEE_RECIPIENT = makeAddr("fee recipient");
    address internal CALLER = makeAddr("caller");
    address internal USER = makeAddr("user");
    address internal ANYONE = makeAddr("anyone");

    function setUp() public {
        SolvBTCWhitelistedSwap implementation = new SolvBTCWhitelistedSwap();
        bytes memory initData = abi.encodeCall(
            SolvBTCWhitelistedSwap.initialize, (
                GOVERNOR, PAUSE_ADMIN, address(SOLVBTC), address(WBTC), 
                CURRENCY_VAULT, FEE_RECIPIENT, 0, false
            )
        );
        solvbtcWhitelistedSwap = SolvBTCWhitelistedSwap(
            address(new ERC1967Proxy(address(implementation), initData))
        );

        vm.startPrank(GOVERNOR);
        SOLVBTC.grantRole(SOLVBTC.SOLVBTC_POOL_BURNER_ROLE(), address(solvbtcWhitelistedSwap));

        deal(address(WBTC), CURRENCY_VAULT, 10e8);
        deal(address(SOLVBTC), CALLER, 20 ether);

        vm.startPrank(CURRENCY_VAULT);
        WBTC.approve(address(solvbtcWhitelistedSwap), 10e8);    
        vm.stopPrank();
    }

    function test_ValidateSwapResult() public {
        uint256 amount = 0.05 ether;
        vm.prank(GOVERNOR);
        solvbtcWhitelistedSwap.setFeeRate(100); // 1%

        uint256 vault_SolvBTC_before = SOLVBTC.balanceOf(CURRENCY_VAULT);
        uint256 vault_WBTC_before = WBTC.balanceOf(CURRENCY_VAULT);
        uint256 feeRecipient_SolvBTC_before = SOLVBTC.balanceOf(FEE_RECIPIENT);
        uint256 feeRecipient_WBTC_before = WBTC.balanceOf(FEE_RECIPIENT);
        uint256 caller_SolvBTC_before = SOLVBTC.balanceOf(CALLER);
        uint256 caller_WBTC_before = WBTC.balanceOf(CALLER);
        uint256 user_SolvBTC_before = SOLVBTC.balanceOf(USER);
        uint256 user_WBTC_before = WBTC.balanceOf(USER);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        uint256 received = solvbtcWhitelistedSwap.swap(USER, amount, 100);

        uint256 expectedGross = 0.05e8;
        uint256 expectedFee = expectedGross / 100;
        uint256 expectedNet = expectedGross - expectedFee;

        assertEq(received, expectedNet, "received amount mismatch");
        assertEq(SOLVBTC.balanceOf(CURRENCY_VAULT), vault_SolvBTC_before, "vault SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(CURRENCY_VAULT), vault_WBTC_before - expectedGross, "vault WBTC balance mismatch");
        assertEq(SOLVBTC.balanceOf(FEE_RECIPIENT), feeRecipient_SolvBTC_before, "fee recipient SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(FEE_RECIPIENT), feeRecipient_WBTC_before + expectedFee, "fee recipient WBTC balance mismatch");
        assertEq(SOLVBTC.balanceOf(CALLER), caller_SolvBTC_before - amount, "caller SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(CALLER), caller_WBTC_before, "caller WBTC balance mismatch");
        assertEq(SOLVBTC.balanceOf(USER), user_SolvBTC_before, "user SolvBTC balance mismatch");
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + expectedNet, "user WBTC balance mismatch");

        SolvBTCWhitelistedSwap.RateLimit memory info = solvbtcWhitelistedSwap.rateLimit();
        assertEq(info.amountSwapped, amount, "rate limit not updated");
        assertEq(info.lastSwappedAt, block.timestamp, "timestamp not refreshed");
    }

    function testSetMaxWindowSwapAmountClampsCurrentUsage() public {
        uint256 initialSwap = 0.08 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), initialSwap);
        solvbtcWhitelistedSwap.swap(USER, initialSwap, 0);

        uint256 newLimit = initialSwap / 4;
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setMaxWindowSwapAmount(newLimit);
        vm.stopPrank();

        SolvBTCWhitelistedSwap.RateLimit memory info = solvbtcWhitelistedSwap.rateLimit();
        assertEq(info.amountSwapped, newLimit, "clamp failed");
        assertEq(info.maxWindowSwapAmount, newLimit, "limit not updated");
    }

    function test_SwapRespectsRateLimits() public {
        uint256 singleLimit = 0.1 ether;
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setMaxSingleSwapAmount(singleLimit);

        uint256 windowLimit = singleLimit * 2;
        solvbtcWhitelistedSwap.setMaxWindowSwapAmount(windowLimit);
        vm.stopPrank();

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), singleLimit * 3);

        solvbtcWhitelistedSwap.swap(USER, singleLimit, 0);
        solvbtcWhitelistedSwap.swap(USER, singleLimit, 0);

        vm.expectRevert("SolvBTCWhitelistedSwap: max window swap amount exceeded");
        solvbtcWhitelistedSwap.swap(USER, 1, 0);

        vm.warp(block.timestamp + 86400 / 2);

        solvbtcWhitelistedSwap.swap(USER, singleLimit, 0);
    }

    function test_SwapAtMaxSingleLimitBoundary() public {
        uint256 limit = 0.02 ether;
        vm.prank(GOVERNOR);
        solvbtcWhitelistedSwap.setMaxSingleSwapAmount(limit);

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), limit);
        solvbtcWhitelistedSwap.swap(USER, limit, 0);

        vm.expectRevert("SolvBTCWhitelistedSwap: max single swap amount exceeded");
        solvbtcWhitelistedSwap.swap(USER, limit + 1, 0);
    }

    function test_RevertWhenSwapZeroAmount() public {
        vm.prank(CALLER);
        vm.expectRevert("SolvBTCWhitelistedSwap: amount cannot be 0");
        solvbtcWhitelistedSwap.swap(USER, 0, 0);
    }

    function test_SetMaxSingleSwapAmountLimit() public {
        uint256 newLimit = 2e16;
        vm.prank(USER);
        vm.expectRevert("only governor");
        solvbtcWhitelistedSwap.setMaxSingleSwapAmount(newLimit);

        vm.prank(GOVERNOR);
        solvbtcWhitelistedSwap.setMaxSingleSwapAmount(newLimit);
        SolvBTCWhitelistedSwap.RateLimit memory info = solvbtcWhitelistedSwap.rateLimit();
        assertEq(info.maxSingleSwapAmount, newLimit, "max single CURRENCY_VAULT amount not updated");
    }

    function test_SetMaxWindowSwapAmountLimit() public {
        vm.prank(USER);
        vm.expectRevert("only governor");
        solvbtcWhitelistedSwap.setMaxWindowSwapAmount(1 ether);

        vm.startPrank(GOVERNOR);
        uint256 newLimit = 3e17;
        solvbtcWhitelistedSwap.setMaxWindowSwapAmount(newLimit);
        SolvBTCWhitelistedSwap.RateLimit memory info = solvbtcWhitelistedSwap.rateLimit();
        assertEq(info.maxWindowSwapAmount, newLimit, "max window CURRENCY_VAULT amount not updated");
        assertEq(info.window, 86400, "window not matched");
    }

    function test_SetSwapFeeRate() public {
        vm.prank(USER);
        vm.expectRevert("only governor");
        solvbtcWhitelistedSwap.setFeeRate(100);

        vm.startPrank(GOVERNOR);
        vm.expectRevert("SolvBTCWhitelistedSwap: fee rate exceeds limit");
        solvbtcWhitelistedSwap.setFeeRate(101);
        solvbtcWhitelistedSwap.setFeeRate(50);
        assertEq(solvbtcWhitelistedSwap.feeRate(), 50, "swap fee rate not updated");
    }

    function test_SetFeeRecipient() public {
        address newFeeRecipient = makeAddr("newFeeRecipient");

        vm.prank(USER);
        vm.expectRevert("only governor");
        solvbtcWhitelistedSwap.setFeeRecipient(newFeeRecipient);

        vm.startPrank(GOVERNOR);
        vm.expectRevert("SolvBTCWhitelistedSwap: fee recipient cannot be 0 address");
        solvbtcWhitelistedSwap.setFeeRecipient(address(0));

        solvbtcWhitelistedSwap.setFeeRate(100); // 1%
        solvbtcWhitelistedSwap.setFeeRecipient(newFeeRecipient);
        vm.stopPrank();

        uint256 feeBalanceBefore = SOLVBTC.balanceOf(newFeeRecipient);
        uint256 amount = 0.05 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        assertEq(WBTC.balanceOf(newFeeRecipient) - feeBalanceBefore, 0.05e8 / 100, "fee recipient should receive CURRENCY_VAULT fee");
    }

    function test_Pause() public {
        vm.prank(GOVERNOR);
        vm.expectRevert("only pause admin");
        solvbtcWhitelistedSwap.pause();

        vm.prank(PAUSE_ADMIN);
        solvbtcWhitelistedSwap.pause();
        assertEq(solvbtcWhitelistedSwap.paused(), true, "contract should be paused");

        uint256 amount = 0.05 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        vm.stopPrank();

        vm.prank(GOVERNOR);
        vm.expectRevert("only pause admin");
        solvbtcWhitelistedSwap.unpause();

        vm.prank(PAUSE_ADMIN);
        solvbtcWhitelistedSwap.unpause();
        assertEq(solvbtcWhitelistedSwap.paused(), false, "contract should be unpaused");

        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
    }

    function test_SwapWhenCallerNotRestrictedAndWhitelistNotEmpty() public {
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setWhitelistEnabled(false);
        solvbtcWhitelistedSwap.setWhitelistConfig(ANYONE, uint64(block.timestamp + 30 days), true);

        uint256 amount = 0.05 ether;
        uint256 user_WBTC_before = WBTC.balanceOf(USER);
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        vm.stopPrank();
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + 0.05e8, "user WBTC balance mismatch");
    }

    function test_SwapWhenCallerRestrictedAndWhitelistEmpty() public {
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setWhitelistEnabled(true);

        uint256 amount = 0.05 ether;
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert("SolvBTCWhitelistedSwap: caller unauthorized");
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        vm.stopPrank();
    }

    function test_SwapWhenWhitelistExpired() public {
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setWhitelistEnabled(true);
        uint64 expiresAt = uint64(block.timestamp + 30 days);
        solvbtcWhitelistedSwap.setWhitelistConfig(CALLER, expiresAt, true);

        uint256 amount = 0.05 ether;
        uint256 user_WBTC_before = WBTC.balanceOf(USER);
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        vm.stopPrank();
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + 0.05e8, "user WBTC balance mismatch");

        vm.warp(expiresAt + 1);
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert("SolvBTCWhitelistedSwap: caller unauthorized");
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        vm.stopPrank();
    }

    function test_SwapWhenCallerWhitelistedAndRateLimited() public {
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setMaxSingleSwapAmount(0.1 ether);
        solvbtcWhitelistedSwap.setMaxWindowSwapAmount(0.12 ether);

        solvbtcWhitelistedSwap.setWhitelistEnabled(true);
        solvbtcWhitelistedSwap.setWhitelistConfig(CALLER, uint64(block.timestamp + 30 days), true);

        uint256 amount = 0.05 ether;
        uint256 user_WBTC_before = WBTC.balanceOf(USER);
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + 0.05e8, "user WBTC balance mismatch");

        amount = 0.11 ether;
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert("SolvBTCWhitelistedSwap: max single swap amount exceeded");
        solvbtcWhitelistedSwap.swap(USER, amount, 0);

        amount = 0.08 ether;
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert("SolvBTCWhitelistedSwap: max window swap amount exceeded");
        solvbtcWhitelistedSwap.swap(USER, amount, 0);

        amount = 0.01 ether;
        vm.startPrank(USER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert("SolvBTCWhitelistedSwap: caller unauthorized");
        solvbtcWhitelistedSwap.swap(CALLER, amount, 0);
        vm.stopPrank();
    }

    function test_SwapWhenCallerWhitelistedAndRateNotLimited() public {
        vm.startPrank(GOVERNOR);
        solvbtcWhitelistedSwap.setMaxSingleSwapAmount(0.1 ether);
        solvbtcWhitelistedSwap.setMaxWindowSwapAmount(0.12 ether);

        solvbtcWhitelistedSwap.setWhitelistEnabled(true);
        solvbtcWhitelistedSwap.setWhitelistConfig(CALLER, uint64(block.timestamp + 30 days), false);

        uint256 amount = 0.2 ether;
        uint256 user_WBTC_before = WBTC.balanceOf(USER);
        vm.startPrank(CALLER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        solvbtcWhitelistedSwap.swap(USER, amount, 0);
        vm.stopPrank();
        assertEq(WBTC.balanceOf(USER), user_WBTC_before + 0.2e8, "user WBTC balance mismatch");

        amount = 0.05 ether;
        vm.startPrank(USER);
        SOLVBTC.approve(address(solvbtcWhitelistedSwap), amount);
        vm.expectRevert("SolvBTCWhitelistedSwap: caller unauthorized");
        solvbtcWhitelistedSwap.swap(CALLER, amount, 0);
        vm.stopPrank();
    }
}
