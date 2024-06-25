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
        return 0xD93F8eE1F3d3f8EaA19a452d5aff638A684deBf9;
    }
}

contract SolvBTCTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "Solv BTC";

    address internal admin = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal governor = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal user = 0xbDfA4f4492dD7b7Cf211209C4791AF8d52BF5c50;

    SftWrappedTokenFactory internal factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);
    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCMultiAssetPool internal solvBTCMultiAssetPool;

    address internal sft = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    address internal sftHolder = 0x0dE2AfF670Dd19394f96Bad9b14a8df11C9a94EB;
    uint256 internal sftId = 85;

    function test_SolvBTCStatusAfterUpgrade() public {
        string memory nameBefore = solvBTC.name();
        string memory symbolBefore = solvBTC.symbol();
        uint8 decimalsBefore = solvBTC.decimals();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(user);

        uint256 holdingValueSftId = solvBTC.holdingValueSftId();
        uint256 holdingValue = IERC3525(sft).balanceOf(holdingValueSftId);

        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        string memory nameAfter = solvBTC.name();
        string memory symbolAfter = solvBTC.symbol();
        uint8 decimalsAfter = solvBTC.decimals();
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(user);

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
        
        assertEq(IERC3525(sft).ownerOf(holdingValueSftId), address(solvBTCMultiAssetPool));
        assertEq(IERC3525(sft).balanceOf(holdingValueSftId), holdingValue);
    }

    function test_ERC165() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        assertTrue(solvBTC.supportsInterface(type(IERC3525Receiver).interfaceId));
        assertTrue(solvBTC.supportsInterface(type(IERC721Receiver).interfaceId));
        assertTrue(solvBTC.supportsInterface(type(IERC165).interfaceId));
    }

    function test_MintBySolvBTCMultiAssetPool() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        vm.startPrank(address(solvBTCMultiAssetPool));
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(user);
        solvBTC.mint(user, 1 ether);
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(user);
        assertEq(totalSupplyAfter - totalSupplyBefore, 1 ether);
        assertEq(userBalanceAfter - userBalanceBefore, 1 ether);
        vm.stopPrank();
    }

    function test_BurnBySolvBTCMultiAssetPool() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        vm.startPrank(address(solvBTCMultiAssetPool));
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(user);
        solvBTC.burn(user, 0.5 ether);
        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(user);
        assertEq(totalSupplyBefore - totalSupplyAfter, 0.5 ether);
        assertEq(userBalanceBefore - userBalanceAfter, 0.5 ether);
        vm.stopPrank();
    }

    function test_RevertWhenCallInitializeAgain() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        solvBTC.initialize("Solv BTC", "SolvBTC");
    }

    function test_RevertWhenCallInitializeV2MoreThanOnce() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        vm.expectRevert(abi.encodeWithSignature("InvalidInitialization()"));
        solvBTC.initializeV2();
    }

    function test_RevertWhenMintByNonSolvBTCMultiAssetPool() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        vm.startPrank(user);
        vm.expectRevert("SolvBTC: only SolvBTCMultiAssetPool");
        solvBTC.mint(user, 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhenBurnByNonSolvBTCMultiAssetPool() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        vm.startPrank(user);
        vm.expectRevert("SolvBTC: only SolvBTCMultiAssetPool");
        solvBTC.burn(user, 0.5 ether);
        vm.stopPrank();
    }

    function test_RevertWhenReceivingERC721() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        vm.startPrank(sftHolder);
        vm.expectRevert(abi.encodeWithSignature("ERC721NotReceivable(address)", sft));
        IERC721(sft).safeTransferFrom(sftHolder, address(solvBTC), sftId);
        vm.stopPrank();
    }

    function test_RevertWhenReceivingERC3525() public {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();

        vm.startPrank(sftHolder);
        vm.expectRevert(abi.encodeWithSignature("ERC3525NotReceivable(address)", sft));
        IERC3525(sft).transferFrom(sftId, address(solvBTC), 0.0001 ether);
        vm.stopPrank();
    }

    function _deploySolvBTCMultiAssetPool() internal {
        vm.startPrank(admin);
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool();
        ProxyAdmin proxyAdmin = new ProxyAdmin(admin);
        bytes32 salt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: salt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize(address)", admin)
        );
        solvBTCMultiAssetPool = SolvBTCMultiAssetPool(address(proxy));
        vm.stopPrank();
    }

    function _upgradeSolvBTC() internal {
        vm.startPrank(admin);
        MockSolvBTC solvBTCImpl = new MockSolvBTC();

        factory.setImplementation(PRODUCT_TYPE, address(solvBTCImpl));
        factory.upgradeBeacon(PRODUCT_TYPE);
        solvBTC.initializeV2();
        vm.stopPrank();
    }

    function _setSolvBTCForMultiAssetPool() internal {
        vm.startPrank(admin);
        solvBTCMultiAssetPool.setSolvBTCOnlyAdmin(address(solvBTC));
        vm.stopPrank();
    }

}