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

contract SolvBTCMultiAssetPoolTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "Solv BTC";

    address internal admin = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal governor = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal user = 0xbDfA4f4492dD7b7Cf211209C4791AF8d52BF5c50;

    SftWrappedTokenFactory internal factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);
    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCMultiAssetPool internal solvBTCMultiAssetPool;

    address internal solvBTCSft = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    uint256 internal solvBTCSlot = 39475026322910990648776764986670533412889479187054865546374468496663502783148;
    uint256 internal solvBTCHoldingValueSftId;

    uint256 internal solvBTCSftId_1 = 50;
    address internal solvBTCSftHolder_1 = 0x08eb297be45f0AcEfe82529FEF03bCf49D6d28CD;
    uint256 internal solvBTCSftId_2 = 85;
    address internal solvBTCSftHolder_2 = 0x0dE2AfF670Dd19394f96Bad9b14a8df11C9a94EB;

    address internal fShareSft = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    uint256 internal solvBTCENASlot = 73370673862338774703804051393194258049657950181644297527289682663167654669645;
    uint256 internal solvBTCENAHoldingValueSftId;
    uint256 internal gmxBTCSlot = 18834720600760682316079182603327587109774167238702271733823387280510631407444;

    address internal solvBTCHolder_1 = 0xB2043c543bb60Fb7AA7265CdcA359A35C4Bc09fa;

    function setUp() public virtual {
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        _setSolvBTCForMultiAssetPool();
    }

    function test_InitialStatus() public {
        assertEq(solvBTCMultiAssetPool.solvBTC(), address(solvBTC));
        assertNotEq(solvBTCMultiAssetPool.solvBTC(), address(0));
    }

    function test_AddSftSlot() public {
        _addDefaultSftSlots();
        assertTrue(solvBTCMultiAssetPool.isSftSlotAllowed(solvBTCSft, solvBTCSlot));
        assertTrue(solvBTCMultiAssetPool.isSftSlotAllowed(fShareSft, solvBTCENASlot));
        assertFalse(solvBTCMultiAssetPool.isSftSlotAllowed(fShareSft, gmxBTCSlot));
    }

    function test_RemoveSftSlot() public {
        _addDefaultSftSlots();
        vm.startPrank(admin);
        solvBTCMultiAssetPool.removeSftSlotOnlyAdmin(fShareSft, solvBTCENASlot);
        assertTrue(solvBTCMultiAssetPool.isSftSlotAllowed(solvBTCSft, solvBTCSlot));
        assertFalse(solvBTCMultiAssetPool.isSftSlotAllowed(fShareSft, solvBTCENASlot));
        assertFalse(solvBTCMultiAssetPool.isSftSlotAllowed(fShareSft, gmxBTCSlot));
        vm.stopPrank();
    }

    function test_Deposit() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(solvBTCSftHolder_1);
        uint256 poolHoldingValueBefore = IERC3525(solvBTCSft).balanceOf(solvBTCHoldingValueSftId);

        vm.startPrank(solvBTCSftHolder_1);
        uint256 sft1Value = IERC3525(solvBTCSft).balanceOf(solvBTCSftId_1);
        IERC3525(solvBTCSft).approve(address(solvBTCMultiAssetPool), solvBTCSftId_1);
        solvBTCMultiAssetPool.deposit(solvBTCSft, solvBTCSftId_1, sft1Value);
        vm.stopPrank();

        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(solvBTCSftHolder_1);
        uint256 poolHoldingValueAfter = IERC3525(solvBTCSft).balanceOf(solvBTCHoldingValueSftId);

        assertEq(totalSupplyAfter - totalSupplyBefore, sft1Value);
        assertEq(userBalanceAfter - userBalanceBefore, sft1Value);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, sft1Value);
    }

    function test_Withdraw() public {
        _addDefaultSftSlots();
        uint256 totalSupplyBefore = solvBTC.totalSupply();
        uint256 userBalanceBefore = solvBTC.balanceOf(solvBTCHolder_1);
        uint256 poolHoldingValueBefore = IERC3525(solvBTCSft).balanceOf(solvBTCHoldingValueSftId);

        vm.startPrank(solvBTCHolder_1);
        uint256 withdrawValue = userBalanceBefore / 4;
        solvBTC.approve(address(solvBTCMultiAssetPool), withdrawValue);
        uint256 toSftId = solvBTCMultiAssetPool.withdraw(solvBTCSft, solvBTCSlot, 0, withdrawValue);
        vm.stopPrank();

        uint256 totalSupplyAfter = solvBTC.totalSupply();
        uint256 userBalanceAfter = solvBTC.balanceOf(solvBTCHolder_1);
        uint256 poolHoldingValueAfter = IERC3525(solvBTCSft).balanceOf(solvBTCHoldingValueSftId);

        assertEq(totalSupplyBefore - totalSupplyAfter, withdrawValue);
        assertEq(userBalanceBefore - userBalanceAfter, withdrawValue);
        assertEq(poolHoldingValueBefore - poolHoldingValueAfter, withdrawValue);
        assertEq(IERC3525(solvBTCSft).balanceOf(toSftId), withdrawValue);
        assertEq(IERC3525(solvBTCSft).ownerOf(toSftId), solvBTCHolder_1);
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

    function _addDefaultSftSlots() internal {
        vm.startPrank(admin);
        solvBTCHoldingValueSftId = IERC3525(solvBTCSft).tokenOfOwnerByIndex(address(solvBTCMultiAssetPool), 0);
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(solvBTCSft, solvBTCSlot, solvBTCHoldingValueSftId);
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(fShareSft, solvBTCENASlot, 0);
        vm.stopPrank();
    }

}