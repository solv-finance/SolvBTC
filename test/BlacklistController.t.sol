// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test} from "../lib/forge-std/src/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BlacklistController} from "../contracts/BlacklistController.sol";
import {SolvBTCV3} from "../contracts/SolvBTCV3.sol";

contract BlacklistControllerHarness is BlacklistController {
    function isBlacklistQuotaReachedHarness(address setter) external view returns (bool) {
        return _isBlacklistQuotaReached(setter);
    }
}

contract BlacklistControllerTest is Test {
    uint256 internal constant DEFAULT_MAX_BLACKLIST_COUNT = 2;

    address internal owner = makeAddr("owner");
    address internal admin = makeAddr("admin");
    address internal secondAdmin = makeAddr("secondAdmin");
    address internal setter = makeAddr("setter");
    address internal remover = makeAddr("remover");
    address internal target = makeAddr("target");
    address internal target2 = makeAddr("target2");

    SolvBTCV3 internal solvBTC;
    BlacklistControllerHarness internal controller;

    function setUp() public {
        SolvBTCV3 solvBTCImpl = new SolvBTCV3();
        solvBTC = SolvBTCV3(
            address(
                new ERC1967Proxy(
                    address(solvBTCImpl),
                    abi.encodeWithSignature("initialize(string,string,address)", "SolvBTC", "SolvBTC", owner)
                )
            )
        );

        BlacklistControllerHarness controllerImpl = new BlacklistControllerHarness();
        controller = BlacklistControllerHarness(
            address(
                new ERC1967Proxy(
                    address(controllerImpl),
                    abi.encodeCall(
                        BlacklistController.initialize, (address(solvBTC), admin, DEFAULT_MAX_BLACKLIST_COUNT)
                    )
                )
            )
        );

        vm.prank(owner);
        solvBTC.updateBlacklistManager(address(controller));
    }

    function test_RevertWhenInitializeWithZeroAdmin() public {
        BlacklistControllerHarness controllerImpl = new BlacklistControllerHarness();

        vm.expectRevert(BlacklistController.InvalidAdmin.selector);
        new ERC1967Proxy(
            address(controllerImpl),
            abi.encodeCall(
                BlacklistController.initialize, (address(solvBTC), address(0), DEFAULT_MAX_BLACKLIST_COUNT)
            )
        );
    }

    function test_RevertWhenInitializeWithZeroSolvBTC() public {
        BlacklistControllerHarness controllerImpl = new BlacklistControllerHarness();

        vm.expectRevert(BlacklistController.InvalidSolvBTC.selector);
        new ERC1967Proxy(
            address(controllerImpl),
            abi.encodeCall(BlacklistController.initialize, (address(0), admin, DEFAULT_MAX_BLACKLIST_COUNT))
        );
    }

    function test_RevertWhenInitializeWithZeroDefaultMaxBlacklistCount() public {
        BlacklistControllerHarness controllerImpl = new BlacklistControllerHarness();

        vm.expectRevert(BlacklistController.InvalidDefaultMaxBlacklistCount.selector);
        new ERC1967Proxy(
            address(controllerImpl),
            abi.encodeCall(BlacklistController.initialize, (address(solvBTC), admin, 0))
        );
    }

    function test_GrantSetterAndBlacklist() public {
        assertEq(address(controller.solvBTC()), address(solvBTC));

        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 2, 0);
        assertEq(controller.isBlacklistSetter(setter), true);

        vm.prank(setter);
        controller.blacklist(target);

        (bool enabled, uint256 maxCount, uint256 usedCount) = controller.getBlacklistSetterStatus(setter);
        assertEq(enabled, true);
        assertEq(maxCount, 2);
        assertEq(usedCount, 1);
        assertEq(solvBTC.isBlacklisted(target), true);
    }

    function test_GrantSetterWithZeroMaxUsesDefaultQuota() public {
        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 0, 0);

        (bool enabled, uint256 maxCount, uint256 usedCount) = controller.getBlacklistSetterStatus(setter);
        assertEq(enabled, true);
        assertEq(maxCount, DEFAULT_MAX_BLACKLIST_COUNT);
        assertEq(usedCount, 0);
    }

    function test_RevertWhenBlacklistQuotaReached() public {
        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 1, 0);

        vm.prank(setter);
        controller.blacklist(target);

        vm.prank(setter);
        vm.expectRevert(abi.encodeWithSelector(BlacklistController.BlacklistQuotaReached.selector, setter));
        controller.blacklist(target2);
    }

    function test_BlacklistQuotaHelperTracksLimit() public {
        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 1, 0);

        assertEq(controller.isBlacklistQuotaReachedHarness(setter), false);

        vm.prank(setter);
        controller.blacklist(target);

        assertEq(controller.isBlacklistQuotaReachedHarness(setter), true);
    }

    function test_RevertWhenBlacklistingAlreadyBlacklistedDoesNotConsumeQuota() public {
        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 2, 0);

        vm.prank(setter);
        controller.blacklist(target);

        vm.prank(setter);
        vm.expectRevert(abi.encodeWithSelector(BlacklistController.AlreadyBlacklisted.selector, target));
        controller.blacklist(target);

        (,, uint256 usedCount) = controller.getBlacklistSetterStatus(setter);
        assertEq(usedCount, 1);
    }

    function test_RevertWhenBlacklistTargetIsZeroAddress() public {
        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 2, 0);

        vm.prank(setter);
        vm.expectRevert(BlacklistController.InvalidTarget.selector);
        controller.blacklist(address(0));
    }

    function test_UnblacklistDoesNotChangeSetterUsage() public {
        vm.startPrank(admin);
        controller.grantBlacklistSetter(setter, 2, 0);
        controller.grantBlacklistRemover(remover);
        vm.stopPrank();

        assertEq(controller.isBlacklistRemover(remover), true);

        vm.prank(setter);
        controller.blacklist(target);

        vm.prank(remover);
        controller.unblacklist(target);

        (,, uint256 usedCount) = controller.getBlacklistSetterStatus(setter);
        assertEq(usedCount, 1);
        assertEq(solvBTC.isBlacklisted(target), false);
    }

    function test_AdminCanUpdateDefaultMaxBlacklistCount() public {
        vm.prank(admin);
        controller.setDefaultMaxBlacklistCount(3);

        vm.prank(admin);
        controller.grantBlacklistSetter(setter, 0, 0);

        (bool enabled, uint256 maxCount, uint256 usedCount) = controller.getBlacklistSetterStatus(setter);
        assertEq(enabled, true);
        assertEq(maxCount, 3);
        assertEq(usedCount, 0);
    }

    function test_RevertWhenDefaultMaxBlacklistCountIsZero() public {
        vm.prank(admin);
        vm.expectRevert(BlacklistController.InvalidDefaultMaxBlacklistCount.selector);
        controller.setDefaultMaxBlacklistCount(0);
    }

    function test_GetBlacklistSetterStatusReturnsDisabledAfterSetterRevoked() public {
        vm.startPrank(admin);
        controller.grantBlacklistSetter(setter, 2, 0);
        controller.revokeBlacklistSetter(setter);
        vm.stopPrank();

        (bool enabled,,) = controller.getBlacklistSetterStatus(setter);
        assertEq(enabled, false);
    }

    function test_GetBlacklistSetterStatusReturnsZeroValuesForUnknownSetter() public {
        (bool enabled, uint256 maxCount, uint256 usedCount) = controller.getBlacklistSetterStatus(target2);
        assertEq(enabled, false);
        assertEq(maxCount, 0);
        assertEq(usedCount, 0);
    }

    function test_AdminTransferAndAcceptWorks() public {
        vm.prank(admin);
        controller.transferAdmin(secondAdmin);

        vm.prank(secondAdmin);
        vm.expectRevert(bytes("only admin"));
        controller.grantBlacklistRemover(remover);

        vm.prank(secondAdmin);
        controller.acceptAdmin();

        vm.prank(secondAdmin);
        controller.grantBlacklistRemover(remover);

        assertEq(controller.isBlacklistRemover(remover), true);
    }

    function test_RevokeBlacklistRemoverDisablesRole() public {
        vm.startPrank(admin);
        controller.grantBlacklistRemover(remover);
        controller.revokeBlacklistRemover(remover);
        vm.stopPrank();

        assertEq(controller.isBlacklistRemover(remover), false);
    }

    function test_RevertWhenBlacklistByNonSetter() public {
        vm.prank(remover);
        vm.expectRevert(abi.encodeWithSelector(BlacklistController.NotBlacklistSetter.selector, remover));
        controller.blacklist(target);
    }

    function test_RevertWhenUnblacklistByNonRemover() public {
        vm.prank(setter);
        vm.expectRevert(abi.encodeWithSelector(BlacklistController.NotBlacklistRemover.selector, setter));
        controller.unblacklist(target);
    }

    function test_RevertWhenUnblacklistTargetIsZeroAddress() public {
        vm.prank(admin);
        controller.grantBlacklistRemover(remover);

        vm.prank(remover);
        vm.expectRevert(BlacklistController.InvalidTarget.selector);
        controller.unblacklist(address(0));
    }

    function test_RevertWhenUnblacklistTargetIsNotBlacklisted() public {
        vm.prank(admin);
        controller.grantBlacklistRemover(remover);

        vm.prank(remover);
        vm.expectRevert(abi.encodeWithSelector(BlacklistController.NotBlacklisted.selector, target));
        controller.unblacklist(target);
    }
}
