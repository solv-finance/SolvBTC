// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrappedTokenFactory.sol";
import "../contracts/SftWrappedToken.sol";

contract SftWrappedTokenFactoryTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "SWT RWADemo";
    string internal constant TOKEN_NAME = "SftWrappedToken RWADemo";
    string internal constant TOKEN_SYMBOL = "SWT-RWADemo";
    address internal constant WRAPPED_SFT_ADDRESS = 0x6089795791F539d664F403c4eFF099F48cE17C75;
    uint256 internal constant WRAPPED_SFT_SLOT = 94872245356118649870025069682337571253044538568877833354046341235689653624276;
    address internal constant NAV_ORACLE_ADDRESS = 0x18937025Dffe1b5e9523aa35dEa0EE55dae9D675;

    address public admin;
    address public governor;

    SftWrappedTokenFactory public factory;
    address public swtImplAddress;

    function setUp() public virtual {
        admin = address(1);
        governor = address(2);

        vm.startPrank(admin);
        factory = new SftWrappedTokenFactory(governor);
        swtImplAddress = address(new SftWrappedToken());
        vm.stopPrank();
    }

    function test_RoleSet() public virtual {
        assertEq(factory.admin(), admin);
        assertEq(factory.governor(), governor);
    }

    function test_DeployProduct() public virtual {
        vm.startPrank(admin);
        // set implementation
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        assertEq(factory.getImplementation(PRODUCT_TYPE), swtImplAddress);

        // deploy beacon
        address beacon = factory.deployBeacon(PRODUCT_TYPE);
        assertEq(factory.getBeacon(PRODUCT_TYPE), beacon);
        assertEq(UpgradeableBeacon(beacon).implementation(), swtImplAddress);
        vm.stopPrank();

        // deploy product proxy
        vm.startPrank(governor);
        address proxy = factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS);
        assertEq(factory.getProxy(PRODUCT_TYPE, PRODUCT_NAME), proxy);
        assertEq(factory.sftWrappedTokens(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT), proxy);
        (string memory name, string memory symbol, address wrappedSft, uint256 wrappedSftSlot, address navOracle) = factory.sftWrappedTokenInfos(proxy);
        assertEq(name, TOKEN_NAME);
        assertEq(symbol, TOKEN_SYMBOL);
        assertEq(wrappedSft, WRAPPED_SFT_ADDRESS);
        assertEq(wrappedSftSlot, WRAPPED_SFT_SLOT);
        assertEq(navOracle, NAV_ORACLE_ADDRESS);

        // validate swt infos
        SftWrappedToken swt = SftWrappedToken(proxy);
        assertEq(swt.name(), TOKEN_NAME);
        assertEq(swt.symbol(), TOKEN_SYMBOL);
        assertEq(swt.wrappedSftAddress(), WRAPPED_SFT_ADDRESS);
        assertEq(swt.wrappedSftSlot(), WRAPPED_SFT_SLOT);
        assertEq(swt.navOracle(), NAV_ORACLE_ADDRESS);
        vm.stopPrank();
    }

    function test_UpgradeBeacon() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        address beacon = factory.deployBeacon(PRODUCT_TYPE);
        vm.stopPrank();

        vm.startPrank(governor);
        address proxy = factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS);
        vm.stopPrank();

        vm.startPrank(admin);
        address newSwtImplAddress = address(new SftWrappedToken());
        factory.setImplementation(PRODUCT_TYPE, newSwtImplAddress);
        factory.upgradeBeacon(PRODUCT_TYPE);
        assertEq(UpgradeableBeacon(beacon).implementation(), newSwtImplAddress);

        // validate swt infos
        SftWrappedToken swt = SftWrappedToken(proxy);
        assertEq(swt.name(), TOKEN_NAME);
        assertEq(swt.symbol(), TOKEN_SYMBOL);
        assertEq(swt.wrappedSftAddress(), WRAPPED_SFT_ADDRESS);
        assertEq(swt.wrappedSftSlot(), WRAPPED_SFT_SLOT);
        assertEq(swt.navOracle(), NAV_ORACLE_ADDRESS);
        vm.stopPrank();
    }

    function test_TransferBeaconOwnership() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        address beacon = factory.deployBeacon(PRODUCT_TYPE);
        assertEq(UpgradeableBeacon(beacon).owner(), address(factory));

        factory.transferBeaconOwnership(PRODUCT_TYPE, governor);
        assertEq(UpgradeableBeacon(beacon).owner(), governor);
        vm.stopPrank();

        vm.startPrank(governor);
        UpgradeableBeacon(beacon).transferOwnership(address(factory));
        assertEq(UpgradeableBeacon(beacon).owner(), address(factory));
        vm.stopPrank();
    }

    function test_RevertWhenSetImplementationByNonAdmin() public virtual {
        vm.startPrank(governor);
        vm.expectRevert("only admin");
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        vm.stopPrank();
    }

    function test_RevertWhenDeployBeaconByNonAdmin() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        vm.stopPrank();

        vm.startPrank(governor);
        vm.expectRevert("only admin");
        factory.deployBeacon(PRODUCT_TYPE);
        vm.stopPrank();
    }

    function test_RevertWhenUpgradeBeaconByNonAdmin() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        factory.deployBeacon(PRODUCT_TYPE);
        address newSwtImplAddress = address(new SftWrappedToken());
        factory.setImplementation(PRODUCT_TYPE, newSwtImplAddress);
        vm.stopPrank();

        vm.startPrank(governor);
        vm.expectRevert("only admin");
        factory.upgradeBeacon(PRODUCT_TYPE);
        vm.stopPrank();
    }

    function test_RevertWhenTransferBeaconOwnershipByNonAdmin() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        factory.deployBeacon(PRODUCT_TYPE);
        vm.stopPrank();

        vm.startPrank(governor);
        vm.expectRevert("only admin");
        factory.transferBeaconOwnership(PRODUCT_TYPE, governor);
        vm.stopPrank();
    }

    function test_RevertWhenDeployProductByNonGovernor() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        factory.deployBeacon(PRODUCT_TYPE);
        vm.expectRevert("only governor");
        factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS);
        vm.stopPrank();
    }

    function test_RevertWhenRemoveProductByNonGovernor() public virtual {
        vm.startPrank(admin);
        factory.setImplementation(PRODUCT_TYPE, swtImplAddress);
        factory.deployBeacon(PRODUCT_TYPE);
        vm.stopPrank();

        vm.startPrank(governor);
        factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS);
        vm.stopPrank();

        vm.startPrank(admin);
        vm.expectRevert("only governor");
        factory.removeProductProxy(PRODUCT_TYPE, PRODUCT_NAME);
        vm.stopPrank();
    }

}