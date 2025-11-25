// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../lib/forge-std/src/Test.sol";
import "../contracts/BTCPlusRedeem.sol";

contract MockSolvBTCYieldToken is ERC20 {
    uint8 private immutable _mockDecimals;
    uint256 public nav;

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 nav_)
        ERC20(name_, symbol_)
    {
        _mockDecimals = decimals_;
        nav = nav_;
    }

    function setNav(uint256 nav_) external {
        nav = nav_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _mockDecimals;
    }

    function getValueByShares(uint256 shares) external view returns (uint256) {
        return shares * nav / (10 ** _mockDecimals);
    }

    function getSharesByValue(uint256 value) external view returns (uint256) {
        return value * (10 ** _mockDecimals) / nav;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}

contract BTCPlusRedeemTest is Test {
    BTCPlusRedeem internal redeem;
    MockSolvBTCYieldToken internal solvBTC;
    MockSolvBTCYieldToken internal btcPlus;

    address internal admin;
    address internal redemptionVault;
    address internal feeRecipient;
    address internal user;

    function setUp() public {
        admin = address(this);
        redemptionVault = makeAddr("vault");
        feeRecipient = makeAddr("fee");
        user = makeAddr("user");

        solvBTC = new MockSolvBTCYieldToken("SolvBTC", "SOLVBTC", 18, 1e18);
        btcPlus = new MockSolvBTCYieldToken("BTCPlus", "BTCPLUS", 18, 1e18);

        vm.warp(2 days);
        BTCPlusRedeem implementation = new BTCPlusRedeem();
        bytes memory initData = abi.encodeCall(
            BTCPlusRedeem.initialize, (admin, redemptionVault, address(solvBTC), address(btcPlus), feeRecipient)
        );
        redeem = BTCPlusRedeem(address(new ERC1967Proxy(address(implementation), initData)));

        btcPlus.mint(user, 100 ether);
        vm.prank(user);
        btcPlus.approve(address(redeem), type(uint256).max);

        solvBTC.mint(redemptionVault, 200 ether);
        vm.prank(redemptionVault);
        solvBTC.approve(address(redeem), type(uint256).max);
    }

    function testWithdrawTransfersValueAndFee() public {
        uint256 amount = 5e15; // 0.005 BTCPlus shares
        redeem.setWithdrawFeeRate(100); // 1%

        uint256 vaultBalanceBefore = solvBTC.balanceOf(redemptionVault);
        uint256 feeRecipientBalanceBefore = solvBTC.balanceOf(feeRecipient);
        uint256 userSolvBTCBefore = solvBTC.balanceOf(user);
        uint256 userBTCPlusBefore = btcPlus.balanceOf(user);

        vm.prank(user);
        uint256 received = redeem.withdrawBTCPlus(amount);

        uint256 expectedGross = amount;
        uint256 expectedFee = expectedGross / 100; // 1%
        uint256 expectedNet = expectedGross - expectedFee;

        assertEq(received, expectedNet);
        assertEq(solvBTC.balanceOf(user) - userSolvBTCBefore, expectedNet, "user net amount mismatch");
        assertEq(
            solvBTC.balanceOf(feeRecipient) - feeRecipientBalanceBefore, expectedFee, "fee recipient mismatch"
        );
        assertEq(
            vaultBalanceBefore - solvBTC.balanceOf(redemptionVault), expectedGross, "vault should send full amount"
        );
        assertEq(btcPlus.balanceOf(user), userBTCPlusBefore - amount, "BTCPlus should be burned");
        assertEq(solvBTC.balanceOf(address(redeem)), 0, "contract should not retain solvBTC");
        assertEq(btcPlus.balanceOf(address(redeem)), 0, "contract should not retain BTCPlus");

        BTCPlusRedeem.RateLimit memory info = redeem.rateLimit();
        assertEq(info.amountWithdrawn, amount, "rate limit not updated");
        assertEq(info.lastWithdrawnAt, block.timestamp, "timestamp not refreshed");
    }

    function testSetMaxWindowWithdrawAmountClampsCurrentUsage() public {
        uint256 initialWithdraw = 8e15;
        vm.prank(user);
        redeem.withdrawBTCPlus(initialWithdraw);

        uint256 newLimit = initialWithdraw / 4;
        uint256 newWindow = 1 hours;
        redeem.setMaxWindowWithdrawAmount(newLimit, newWindow);

        BTCPlusRedeem.RateLimit memory info = redeem.rateLimit();
        assertEq(info.amountWithdrawn, newLimit, "clamp failed");
        assertEq(info.maxWindowWithdrawAmount, newLimit, "limit not updated");
        assertEq(info.window, newWindow, "window not updated");
    }

    function testWithdrawRespectsRateLimits() public {
        uint256 singleLimit = 1e17; // 0.1 BTCPlus
        redeem.setMaxSingleWithdrawAmount(singleLimit);

        uint256 newWindow = 1 days;
        uint256 windowLimit = singleLimit * 2;
        redeem.setMaxWindowWithdrawAmount(windowLimit, newWindow);

        vm.prank(user);
        redeem.withdrawBTCPlus(singleLimit);

        vm.prank(user);
        redeem.withdrawBTCPlus(singleLimit);

        vm.prank(user);
        vm.expectRevert("BTCPlusRedeem: amount exceeds daily withdraw amount");
        redeem.withdrawBTCPlus(1);

        vm.warp(block.timestamp + newWindow);

        vm.prank(user);
        redeem.withdrawBTCPlus(singleLimit);
    }

    function testWithdrawZeroAmountReverts() public {
        vm.prank(user);
        vm.expectRevert("BTCPlusRedeem: amount cannot be 0");
        redeem.withdrawBTCPlus(0);
    }

    function testWithdrawAtMaxSingleLimitBoundary() public {
        uint256 limit = 5e16;
        redeem.setMaxSingleWithdrawAmount(limit);

        vm.prank(user);
        redeem.withdrawBTCPlus(limit);

        vm.prank(user);
        vm.expectRevert("BTCPlusRedeem: amount exceeds single withdraw amount");
        redeem.withdrawBTCPlus(limit + 1);
    }

    function testSetMaxSingleWithdrawAmountOnlyAdmin() public {
        uint256 newLimit = 2e16;
        vm.prank(user);
        vm.expectRevert("only admin");
        redeem.setMaxSingleWithdrawAmount(newLimit);

        redeem.setMaxSingleWithdrawAmount(newLimit);
        BTCPlusRedeem.RateLimit memory info = redeem.rateLimit();
        assertEq(info.maxSingleWithdrawAmount, newLimit, "max single withdraw amount not updated");
    }

    function testSetMaxWindowWithdrawAmountValidations() public {
        vm.prank(user);
        vm.expectRevert("only admin");
        redeem.setMaxWindowWithdrawAmount(1 ether, 1 days);

        vm.expectRevert("BTCPlusRedeem: window cannot be 0");
        redeem.setMaxWindowWithdrawAmount(1 ether, 0);

        uint256 newLimit = 3e17;
        uint256 newWindow = 2 days;
        redeem.setMaxWindowWithdrawAmount(newLimit, newWindow);
        BTCPlusRedeem.RateLimit memory info = redeem.rateLimit();
        assertEq(info.maxWindowWithdrawAmount, newLimit, "max window withdraw amount not updated");
        assertEq(info.window, newWindow, "window not updated");
    }

    function testSetWithdrawFeeRateOnlyAdmin() public {
        vm.prank(user);
        vm.expectRevert("only admin");
        redeem.setWithdrawFeeRate(100);

        uint64 newFeeRate = 250;
        redeem.setWithdrawFeeRate(newFeeRate);
        assertEq(redeem.withdrawFeeRate(), newFeeRate, "withdraw fee rate not updated");
    }

    function testSetFeeRecipientRequiresAdminAndNonZero() public {
        address newFeeRecipient = makeAddr("newFeeRecipient");

        vm.prank(user);
        vm.expectRevert("only admin");
        redeem.setFeeRecipient(newFeeRecipient);

        vm.expectRevert("BTCPlusRedeem: fee recipient cannot be 0 address");
        redeem.setFeeRecipient(address(0));

        redeem.setWithdrawFeeRate(100); // 1%
        redeem.setFeeRecipient(newFeeRecipient);

        uint256 feeBalanceBefore = solvBTC.balanceOf(newFeeRecipient);
        uint256 amount = 5e15;
        vm.prank(user);
        redeem.withdrawBTCPlus(amount);
        assertGt(
            solvBTC.balanceOf(newFeeRecipient),
            feeBalanceBefore,
            "fee recipient should receive withdraw fee"
        );
    }

    function testSetRedemptionVaultRequiresAdminAndNonZero() public {
        address oldVault = redemptionVault;
        address newVault = makeAddr("newRedemptionVault");

        vm.prank(user);
        vm.expectRevert("only admin");
        redeem.setRedemptionVault(newVault);

        vm.expectRevert("BTCPlusRedeem: redemption vault cannot be 0 address");
        redeem.setRedemptionVault(address(0));

        solvBTC.mint(newVault, 200 ether);
        vm.prank(newVault);
        solvBTC.approve(address(redeem), type(uint256).max);

        redeem.setRedemptionVault(newVault);

        uint256 amount = 5e15;
        uint256 oldVaultBalanceBefore = solvBTC.balanceOf(oldVault);
        uint256 newVaultBalanceBefore = solvBTC.balanceOf(newVault);

        vm.prank(user);
        redeem.withdrawBTCPlus(amount);

        assertEq(
            solvBTC.balanceOf(oldVault),
            oldVaultBalanceBefore,
            "old redemption vault should remain untouched"
        );
        assertEq(
            newVaultBalanceBefore - solvBTC.balanceOf(newVault),
            amount,
            "new redemption vault should supply solvBTC"
        );
    }
}
