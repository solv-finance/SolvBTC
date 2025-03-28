// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrappedTokenFactory.sol";
import "../contracts/SolvBTCFactoryV3.sol";
import "../contracts/SftWrappedToken.sol";
import "../contracts/SolvBTCV3.sol";

contract SolvBTCFactoryV3Test is Test {

    string internal constant PRODUCT_TYPE_SWT = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME_SWT = "Solv BTC";

    string internal constant PRODUCT_TYPE_SOLVBTC = "SolvBTC";
    string internal constant PRODUCT_NAME_SOLVBTC = "SolvBTC";
    string internal constant TOKEN_NAME_SOLVBTC = "Solv BTC";
    string internal constant TOKEN_SYMBOL_SOLVBTC = "SolvBTC";

    string internal constant PRODUCT_TYPE_SOLVBTC_YIELD_TOKENS = "SolvBTC.YT";
    string internal constant PRODUCT_NAME_SOLVBTC_BBN = "SolvBTC.BBN";
    string internal constant TOKEN_NAME_SOLVBTC_BBN = "SolvBTC Babylon";
    string internal constant TOKEN_SYMBOL_SOLVBTC_BBN = "SolvBTC.BBN";

    address internal constant SOLVBTC_SFT = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    uint256 internal constant SOLVBTC_SLOT = 39475026322910990648776764986670533412889479187054865546374468496663502783148;

    address internal ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal GOVERNOR = makeAddr("GOVERNOR");
    address internal USER = 0xbDfA4f4492dD7b7Cf211209C4791AF8d52BF5c50;
    address internal OTHERS = makeAddr("OTHERS");

    SolvBTCFactoryV3 internal solvBTCFactory;
    address internal solvBTCImplAddress;

    function setUp() public {
        vm.startPrank(ADMIN);
        solvBTCFactory = new SolvBTCFactoryV3(ADMIN, GOVERNOR);
        solvBTCImplAddress = address(new SolvBTCV3());
        vm.stopPrank();
    }

    function test_Role() public {
        assertEq(solvBTCFactory.admin(), ADMIN);
        assertEq(solvBTCFactory.governor(), GOVERNOR);
    }

    function test_DeployProduct() public {
        // deploy beacon
        vm.startPrank(ADMIN);
        address beacon = solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.stopPrank();

        assertEq(solvBTCFactory.getImplementation(PRODUCT_TYPE_SOLVBTC), solvBTCImplAddress);
        assertEq(solvBTCFactory.getBeacon(PRODUCT_TYPE_SOLVBTC), beacon);
        assertEq(UpgradeableBeacon(beacon).implementation(), solvBTCImplAddress);

        // deploy product proxy
        vm.startPrank(GOVERNOR);
        address proxy = solvBTCFactory.deployProductProxy(
            PRODUCT_TYPE_SOLVBTC, PRODUCT_NAME_SOLVBTC, TOKEN_NAME_SOLVBTC, TOKEN_SYMBOL_SOLVBTC, ADMIN
        );
        vm.stopPrank();

        assertEq(solvBTCFactory.getProxy(PRODUCT_TYPE_SOLVBTC, PRODUCT_NAME_SOLVBTC), proxy);
        assertEq(SolvBTCV3(proxy).name(), TOKEN_NAME_SOLVBTC);
        assertEq(SolvBTCV3(proxy).symbol(), TOKEN_SYMBOL_SOLVBTC);
    }

    function test_UpgradeBeacon() public {
        vm.startPrank(ADMIN);
        address beacon = solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.stopPrank();

        vm.startPrank(GOVERNOR);
        address proxy = solvBTCFactory.deployProductProxy(
            PRODUCT_TYPE_SOLVBTC, PRODUCT_NAME_SOLVBTC, TOKEN_NAME_SOLVBTC, TOKEN_SYMBOL_SOLVBTC, ADMIN
        );
        vm.stopPrank();

        vm.startPrank(ADMIN);
        address newSolvBTCImplAddress = address(new SftWrappedToken());
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, newSolvBTCImplAddress);
        vm.stopPrank();

        assertEq(solvBTCFactory.getImplementation(PRODUCT_TYPE_SOLVBTC), newSolvBTCImplAddress);
        assertEq(solvBTCFactory.getBeacon(PRODUCT_TYPE_SOLVBTC), beacon);
        assertEq(UpgradeableBeacon(beacon).implementation(), newSolvBTCImplAddress);

        assertEq(SolvBTCV3(proxy).name(), TOKEN_NAME_SOLVBTC);
        assertEq(SolvBTCV3(proxy).symbol(), TOKEN_SYMBOL_SOLVBTC);
    }

    function test_TransferBeaconOwnership() public {
        vm.startPrank(ADMIN);
        address beacon = solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        assertEq(UpgradeableBeacon(beacon).owner(), address(solvBTCFactory));

        solvBTCFactory.transferBeaconOwnership(PRODUCT_TYPE_SOLVBTC, OTHERS);
        assertEq(UpgradeableBeacon(beacon).owner(), OTHERS);
        vm.stopPrank();

        vm.startPrank(OTHERS);
        UpgradeableBeacon(beacon).transferOwnership(address(solvBTCFactory));
        assertEq(UpgradeableBeacon(beacon).owner(), address(solvBTCFactory));
        vm.stopPrank();
    }

    function test_RevertWhenDeployBeaconByNonAdmin() public {
        vm.startPrank(GOVERNOR);
        vm.expectRevert("only admin");
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.stopPrank();
    }

    function test_RevertWhenUpgradeBeaconByNonAdmin() public {
        vm.startPrank(ADMIN);
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.stopPrank();

        vm.startPrank(GOVERNOR);
        address newSolvBTCImplAddress = address(new SolvBTCV3());
        vm.expectRevert("only admin");
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, newSolvBTCImplAddress);
        vm.stopPrank();
    }

    function test_RevertWhenTransferBeaconOwnershipByNonAdmin() public {
        vm.startPrank(ADMIN);
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.stopPrank();

        vm.startPrank(GOVERNOR);
        vm.expectRevert("only admin");
        solvBTCFactory.transferBeaconOwnership(PRODUCT_TYPE_SOLVBTC, GOVERNOR);
        vm.stopPrank();
    }

    function test_RevertWhenDeployProductByNonGovernor() public {
        vm.startPrank(ADMIN);
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.expectRevert("only governor");
        solvBTCFactory.deployProductProxy(PRODUCT_TYPE_SOLVBTC, PRODUCT_NAME_SOLVBTC, TOKEN_NAME_SOLVBTC, TOKEN_SYMBOL_SOLVBTC, ADMIN);
        vm.stopPrank();
    }

    function test_RevertWhenRemoveProductByNonAdmin() public {
        vm.startPrank(ADMIN);
        solvBTCFactory.setImplementation(PRODUCT_TYPE_SOLVBTC, solvBTCImplAddress);
        vm.stopPrank();

        vm.startPrank(GOVERNOR);
        solvBTCFactory.deployProductProxy(PRODUCT_TYPE_SOLVBTC, PRODUCT_NAME_SOLVBTC, TOKEN_NAME_SOLVBTC, TOKEN_SYMBOL_SOLVBTC, ADMIN);
        vm.expectRevert("only admin");
        solvBTCFactory.removeProductProxy(PRODUCT_TYPE_SOLVBTC, PRODUCT_NAME_SOLVBTC);
        vm.stopPrank();
    }

}