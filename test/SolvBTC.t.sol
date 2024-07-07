// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrapRouter.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";

contract MockSolvBTC is SolvBTC {
    function solvBTCMultiAssetPool() public view virtual override returns (address) {
        return 0xC221Bc51373FD7acf3C169205113c7b11108AA11;
    }
}

contract SolvBTCTest is Test {
    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "Solv BTC";

    SftWrappedTokenFactory internal factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);
    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCMultiAssetPool internal solvBTCMultiAssetPool;
    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    address internal constant SOLVBTC_SFT = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    address internal constant SOLVBTC_SFT_HOLDER = 0x0dE2AfF670Dd19394f96Bad9b14a8df11C9a94EB;
    uint256 internal constant SOLVBTC_SFT_ID = 85;

    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant GOVERNOR = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant USER = 0xbDfA4f4492dD7b7Cf211209C4791AF8d52BF5c50;

    function test_ERC165() public {
        _upgradeAndSetup();
        assertTrue(solvBTC.supportsInterface(type(IERC3525Receiver).interfaceId));
        assertTrue(solvBTC.supportsInterface(type(IERC721Receiver).interfaceId));
        assertTrue(solvBTC.supportsInterface(type(IERC165).interfaceId));
    }

    function test_SolvBTCStatusAfterUpgrade() public {
        string memory nameBefore = solvBTC.name();
        string memory symbolBefore = solvBTC.symbol();
        uint8 decimalsBefore = solvBTC.decimals();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(USER);

        uint256 holdingValueSftId = solvBTC.holdingValueSftId();
        uint256 holdingValue = IERC3525(SOLVBTC_SFT).balanceOf(holdingValueSftId);

        _upgradeAndSetup();

        string memory nameAfter = solvBTC.name();
        string memory symbolAfter = solvBTC.symbol();
        uint8 decimalsAfter = solvBTC.decimals();
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(USER);

        assertEq(nameBefore, nameAfter);
        assertEq(symbolBefore, symbolAfter);
        assertEq(decimalsBefore, decimalsAfter);
        assertEq(totalSupplyBefore, totalSupplyAfter);
        assertEq(userBalanceBefore, userBalanceAfter);

        assertEq(solvBTC.wrappedSftAddress(), address(0));
        assertEq(solvBTC.wrappedSftSlot(), 0);
        assertEq(solvBTC.navOracle(), address(0));
        assertEq(solvBTC.holdingValueSftId(), 0);

        assertEq(solvBTC.solvBTCMultiAssetPool(), address(solvBTCMultiAssetPool));
        assertNotEq(solvBTC.solvBTCMultiAssetPool(), address(0));
        
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(holdingValueSftId), address(solvBTCMultiAssetPool));
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(holdingValueSftId), holdingValue);
    }

    /** Tests for initialization functions */
    function test_RevertWhenCallInitializeRepeatedly() public {
        _upgradeAndSetup();
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        solvBTC.initialize("Solv BTC", "SolvBTC");
    }

    function test_RevertWhenCallInitializeV2Repeatedly() public {
        _upgradeAndSetup();
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        solvBTC.initializeV2();
    }

    /** Tests for mint/burn functions */
    function test_MintBySolvBTCMultiAssetPool() public {
        _upgradeAndSetup();
        vm.startPrank(address(solvBTCMultiAssetPool));
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(USER);
        solvBTC.mint(USER, 1 ether);
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(USER);
        assertEq(totalSupplyAfter - totalSupplyBefore, 1 ether);
        assertEq(userBalanceAfter - userBalanceBefore, 1 ether);
        vm.stopPrank();
    }

    function test_MintByAnotherMinter() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), USER);
        vm.stopPrank();

        vm.startPrank(USER);
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(USER);
        solvBTC.burn(USER, 0.5 ether);
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(USER);
        assertEq(totalSupplyBefore - totalSupplyAfter, 0.5 ether);
        assertEq(userBalanceBefore - userBalanceAfter, 0.5 ether);
        vm.stopPrank();
    }

    function test_BurnBySolvBTCMultiAssetPool() public {
        _upgradeAndSetup();
        vm.startPrank(address(solvBTCMultiAssetPool));
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(USER);
        solvBTC.burn(USER, 0.5 ether);
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(USER);
        assertEq(totalSupplyBefore - totalSupplyAfter, 0.5 ether);
        assertEq(userBalanceBefore - userBalanceAfter, 0.5 ether);
        vm.stopPrank();
    }

    function test_BurnByAnotherMinter() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), USER);
        vm.stopPrank();

        vm.startPrank(USER);
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(USER);
        solvBTC.burn(USER, 0.5 ether);
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(USER);
        assertEq(totalSupplyBefore - totalSupplyAfter, 0.5 ether);
        assertEq(userBalanceBefore - userBalanceAfter, 0.5 ether);
        vm.stopPrank();
    }

    function test_RevertWhenMintByNonMinter() public {
        _upgradeAndSetup();
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", USER, solvBTC.SOLVBTC_MINTER_ROLE()));
        solvBTC.mint(USER, 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhenBurnByNonMinter() public {
        _upgradeAndSetup();
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", USER, solvBTC.SOLVBTC_MINTER_ROLE()));
        solvBTC.burn(USER, 0.5 ether);
        vm.stopPrank();
    }

    /** Tests for receiving ERC721/ERC3525 tokens */
    function test_RevertWhenReceivingERC721() public {
        _upgradeAndSetup();
        vm.startPrank(SOLVBTC_SFT_HOLDER);
        vm.expectRevert(abi.encodeWithSignature("ERC721NotReceivable(address)", SOLVBTC_SFT));
        IERC721(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER, address(solvBTC), SOLVBTC_SFT_ID);
        vm.stopPrank();
    }

    function test_RevertWhenReceivingERC3525() public {
        _upgradeAndSetup();
        vm.startPrank(SOLVBTC_SFT_HOLDER);
        vm.expectRevert(abi.encodeWithSignature("ERC3525NotReceivable(address)", SOLVBTC_SFT));
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID, address(solvBTC), 0.0001 ether);
        vm.stopPrank();
    }

    /** Tests for Ownership functions */
    function test_OwnershipInitialStatus() public {
        _upgradeAndSetup();
        assertEq(solvBTC.owner(), ADMIN);
        assertEq(solvBTC.pendingOwner(), address(0));
        assertTrue(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), ADMIN));
    }

    function test_TransferOwnership() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.transferOwnership(USER);
        vm.stopPrank();
        assertEq(solvBTC.owner(), ADMIN);
        assertEq(solvBTC.pendingOwner(), USER);

        vm.startPrank(USER);
        solvBTC.acceptOwnership();
        vm.stopPrank();
        assertEq(solvBTC.owner(), USER);
        assertEq(solvBTC.pendingOwner(), address(0));
    }

    function test_RevertWhenTransferOwnershipByNonAdmin() public {
        _upgradeAndSetup();
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER));
        solvBTC.transferOwnership(USER);
        vm.stopPrank();
    }

    function test_RevertWhenAcceptOwnershipByNonPendingAdmin() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.transferOwnership(USER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", ADMIN));
        solvBTC.acceptOwnership();
        vm.stopPrank();
    }

    /** Tests for AccessControl functions */
    function test_AccessControlInitialStatus() public {
        _upgradeAndSetup();
        assertTrue(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), ADMIN));
    }

    function test_GrantAdminRole() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.grantRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER);
        vm.stopPrank();
        assertTrue(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), ADMIN));
        assertTrue(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER));
    }

    function test_GrantMinterRole() public {
        _upgradeAndSetup();
        bytes32 minterRole = keccak256(abi.encode("minter"));
        vm.startPrank(ADMIN);
        solvBTC.grantRole(minterRole, USER);
        vm.stopPrank();
        assertEq(solvBTC.getRoleAdmin(minterRole), solvBTC.DEFAULT_ADMIN_ROLE());
        assertFalse(solvBTC.hasRole(minterRole, ADMIN));
        assertTrue(solvBTC.hasRole(minterRole, USER));
    }

    function test_RevokeAdminRole() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.grantRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER);
        solvBTC.revokeRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER);
        vm.stopPrank();
        assertTrue(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), ADMIN));
        assertFalse(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER));
    }

    function test_RevertWhenGrantRoleByNonAdminRole() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), USER);
        vm.stopPrank();
        vm.startPrank(USER);
        bytes32 minterRole = solvBTC.SOLVBTC_MINTER_ROLE();
        vm.expectRevert(abi.encodeWithSignature("AccessControlUnauthorizedAccount(address,bytes32)", USER, solvBTC.DEFAULT_ADMIN_ROLE()));
        solvBTC.grantRole(minterRole, ADMIN);
        vm.stopPrank();
    }

    function test_RenounceAdminRole() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        solvBTC.grantRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER);
        solvBTC.renounceRole(solvBTC.DEFAULT_ADMIN_ROLE(), ADMIN);
        vm.stopPrank();
        assertFalse(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), ADMIN));
        assertTrue(solvBTC.hasRole(solvBTC.DEFAULT_ADMIN_ROLE(), USER));
    }

    /** Tests for set SolvBTCMultiAssetPool */
    function test_SetSolvBTCMultiAssetPool() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        solvBTC.initializeV2();
        vm.startPrank(ADMIN);
        solvBTC.setSolvBTCMultiAssetPool(address(solvBTCMultiAssetPool));
        vm.stopPrank();
        assertEq(solvBTC.solvBTCMultiAssetPool(), address(solvBTCMultiAssetPool));
    }

    function test_RevertWhenSetWithInvalidSolvBTCMultiAssetPool() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        solvBTC.initializeV2();
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTC: invalid solvBTCMultiAssetPool address");
        solvBTC.setSolvBTCMultiAssetPool(address(0));
        vm.stopPrank();
    }

    function test_RevertWhenSetSolvBTCMultiAssetPoolRepeatedly() public {
        _upgradeAndSetup();
        vm.startPrank(ADMIN);
        vm.expectRevert("SolvBTC: solvBTCMultiAssetPool already set");
        solvBTC.setSolvBTCMultiAssetPool(address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }

    function test_RevertWhenSetSolvBTCMultiAssetPoolByNonAdmin() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        solvBTC.initializeV2();
        vm.startPrank(USER);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", USER));
        solvBTC.setSolvBTCMultiAssetPool(address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }


    /** Internal functions */
    function _upgradeAndSetup() internal {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        _setupSolvBTC();
        _setupSolvBTCMultiAssetPool();
    }

    function _deploySolvBTCMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize(address)", ADMIN)
        );
        solvBTCMultiAssetPool = SolvBTCMultiAssetPool(address(proxy));
        vm.stopPrank();
    }

    function _upgradeSolvBTC() internal {
        vm.startPrank(ADMIN);
        MockSolvBTC solvBTCImpl = new MockSolvBTC();
        factory.setImplementation(PRODUCT_TYPE, address(solvBTCImpl));
        factory.upgradeBeacon(PRODUCT_TYPE);
        vm.stopPrank();
    }

    function _setupSolvBTC() internal {
        vm.startPrank(ADMIN);
        solvBTC.initializeV2();
        solvBTC.setSolvBTCMultiAssetPool(address(solvBTCMultiAssetPool));
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }

    function _setupSolvBTCMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        solvBTCMultiAssetPool.setSolvBTCOnlyAdmin(address(solvBTC));
        vm.stopPrank();
    }

}