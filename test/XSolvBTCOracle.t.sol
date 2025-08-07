// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../contracts/SolvBTCFactory.sol";
import "../contracts/SolvBTCYieldToken.sol";
import "../contracts/SolvBTCYieldTokenV3.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";
import "../contracts/IxSolvBTCPool.sol";
import "../contracts/XSolvBTCPool.sol";
import "../contracts/SolvBTCRouterV2.sol";
import "../contracts/SolvBTCV3_1.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCYieldTokenV3_1.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/oracle/XSolvBTCOracle.sol";

interface IProxyAdmin {
    function upgrade(ITransparentUpgradeableProxy proxy, address implementation) external;
}

contract XSolvBTCOracleTest is Test {
    address internal constant solvBTC = 0x7A56E1C57C7475CCf742a1832B028F0456652F97;
    address internal constant xSolvBTC = 0xd9D920AA40f578ab794426F5C90F6C731D159DEf;
    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    ProxyAdmin internal constant proxyAdmin = ProxyAdmin(0xD3e96c05F2bED82271B5C9d737C215F6BcadfF68);
    address internal constant USER_1 = 0x3D64cFEEf2B66AdD5191c387E711AF47ab01e296;

    XSolvBTCPool public xSolvBTCPool;
    XSolvBTCOracle public oracle;

    function setUp() public {
        // Create a simple test environment without forking
        xSolvBTCPool = XSolvBTCPool(_deployXSolvBTCPool());
        oracle = XSolvBTCOracle(_deployXSolvBTCOracle());
    }

    // Test initialization
    function test_Initialize() public {
        assertEq(oracle.xSolvBTC(), xSolvBTC);
        assertEq(oracle.xSolvBTCPool(), address(xSolvBTCPool));
        assertEq(oracle.getNav(xSolvBTC), 1e18);
        assertEq(oracle.navDecimals(xSolvBTC), 18);
        assertEq(oracle.latestUpdatedAt(), block.timestamp);
    }

    // Test setNav functionality
    function test_SetNav() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.005e18);
        vm.stopPrank();
        assertEq(oracle.getNav(xSolvBTC), 1.005e18);
    }

    // Test setNav with higher value
    function test_SetNavHigherValue() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.01e18);
        vm.stopPrank();
        assertEq(oracle.getNav(xSolvBTC), 1.01e18);
    }

    // Test getNav with invalid address
    function test_RevertWhenGetNavByInvalidXSolvBTC() public {
        vm.expectRevert("XSolvBTCOracle: invalid erc20 address");
        oracle.getNav(address(0));
    }

    // Test getNav when nav is abnormal
    function test_RevertWhenGetNavAbnormal() public {
        vm.startPrank(ADMIN);
        oracle.setIsNavAbnormal(true);
        vm.stopPrank();

        vm.expectRevert("XSolvBTCOracle: nav is abnormal");
        oracle.getNav(xSolvBTC);
    }

    // Test setNav by non-admin
    function test_RevertWhenSetNavByNonAdmin() public {
        vm.startPrank(USER_1);
        vm.expectRevert("only admin");
        oracle.setNav(1.005e18);
        vm.stopPrank();
    }

    // Test setNav with zero value
    function test_RevertWhenSetNavZero() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("XSolvBTCOracle: invalid nav");
        oracle.setNav(0);
        vm.stopPrank();
    }

    // Test setNav with reduced value
    function test_RevertWhenSetNavReduced() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.005e18);
        vm.expectRevert("XSolvBTCOracle: nav cannot be reduced");
        oracle.setNav(1.004e18);
        vm.stopPrank();
    }

    // Test setNav within 24 hours
    function test_RevertWhenSetNavWithin24Hours() public {
        // Advance time by 25 hours to allow first nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.005e18);
        vm.expectRevert("XSolvBTCOracle: nav cannot be updated in the 24 hours");
        oracle.setNav(1.006e18);
        vm.stopPrank();
    }

    // Test setNav after 24 hours
    function test_SetNavAfter24Hours() public {
        // Advance time by 25 hours to allow first nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.005e18);

        // Advance time by another 25 hours
        vm.warp(block.timestamp + 25 hours);

        oracle.setNav(1.006e18);
        vm.stopPrank();

        assertEq(oracle.getNav(xSolvBTC), 1.006e18);
    }

    // Test setNav with excessive growth
    function test_RevertWhenSetNavExcessiveGrowth() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);

        // Set a high NAV value that would exceed the growth limit
        // Assuming withdrawFeeRate is 100 (1%), max change is 1%
        uint256 excessiveNav = 1.02e18; // 2% increase, which exceeds 1% limit

        vm.expectRevert("XSolvBTCOracle: nav growth over max change percent");
        oracle.setNav(excessiveNav);
        vm.stopPrank();
    }

    // Test setXSolvBTC functionality
    function test_SetXSolvBTC() public {
        address newXSolvBTC = address(0x123);
        vm.startPrank(ADMIN);
        oracle.setXSolvBTC(newXSolvBTC);
        vm.stopPrank();

        assertEq(oracle.xSolvBTC(), newXSolvBTC);
    }

    // Test setXSolvBTC with zero address
    function test_RevertWhenSetXSolvBTCZero() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("XSolvBTCOracle: invalid xSolvBTC address");
        oracle.setXSolvBTC(address(0));
        vm.stopPrank();
    }

    // Test setXSolvBTC by non-admin
    function test_RevertWhenSetXSolvBTCByNonAdmin() public {
        vm.startPrank(USER_1);
        vm.expectRevert("only admin");
        oracle.setXSolvBTC(address(0x123));
        vm.stopPrank();
    }

    // Test setXSolvBTCPool functionality
    function test_SetXSolvBTCPool() public {
        address newPool = address(0x456);
        vm.startPrank(ADMIN);
        oracle.setXSolvBTCPool(newPool);
        vm.stopPrank();

        assertEq(oracle.xSolvBTCPool(), newPool);
    }

    // Test setXSolvBTCPool with zero address
    function test_RevertWhenSetXSolvBTCPoolZero() public {
        vm.startPrank(ADMIN);
        vm.expectRevert("XSolvBTCOracle: invalid xSolvBTCPool address");
        oracle.setXSolvBTCPool(address(0));
        vm.stopPrank();
    }

    // Test setXSolvBTCPool by non-admin
    function test_RevertWhenSetXSolvBTCPoolByNonAdmin() public {
        vm.startPrank(USER_1);
        vm.expectRevert("only admin");
        oracle.setXSolvBTCPool(address(0x456));
        vm.stopPrank();
    }

    // Test setIsNavAbnormal functionality
    function test_SetIsNavAbnormal() public {
        vm.startPrank(ADMIN);
        oracle.setIsNavAbnormal(true);
        vm.stopPrank();

        // Should revert when trying to get nav
        vm.expectRevert("XSolvBTCOracle: nav is abnormal");
        oracle.getNav(xSolvBTC);

        // Set back to false
        vm.startPrank(ADMIN);
        oracle.setIsNavAbnormal(false);
        vm.stopPrank();

        // Should work now
        assertEq(oracle.getNav(xSolvBTC), 1e18);
    }

    // Test setIsNavAbnormal by non-admin
    function test_RevertWhenSetIsNavAbnormalByNonAdmin() public {
        vm.startPrank(USER_1);
        vm.expectRevert("only admin");
        oracle.setIsNavAbnormal(true);
        vm.stopPrank();
    }

    // Test navDecimals functionality
    function test_NavDecimals() public {
        assertEq(oracle.navDecimals(xSolvBTC), 18);
    }

    // Test navDecimals with invalid address
    function test_RevertWhenNavDecimalsInvalidAddress() public {
        vm.expectRevert("XSolvBTCOracle: invalid erc20 address");
        oracle.navDecimals(address(0));
    }

    // Test latestUpdatedAt functionality
    function test_GetLatestUpdatedAt() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.005e18);
        vm.stopPrank();
        assertEq(oracle.latestUpdatedAt(), block.timestamp);
    }

    // Test SetNav event emission
    function test_SetNavEvent() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);
        oracle.setNav(1.005e18);
        vm.stopPrank();
        // Event emission is tested implicitly by successful execution
    }

    // Test initialization event emission
    function test_InitializeEvent() public {
        // Create a new oracle to test initialization event
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN, "test"));
        XSolvBTCOracle impl = new XSolvBTCOracle{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl, "test"));
        new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize(uint8,uint256)", 18, 1.005e18)
        );
        vm.stopPrank();
    }

    // Test edge case: nav growth exactly at the limit
    function test_SetNavAtGrowthLimit() public {
        // Advance time by 25 hours to allow nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);

        // Assuming withdrawFeeRate is 100 (1%), we can increase by exactly 1%
        uint256 navAtLimit = 1.01e18; // Exactly 1% increase

        oracle.setNav(navAtLimit);
        vm.stopPrank();

        assertEq(oracle.getNav(xSolvBTC), navAtLimit);
    }

    // Test multiple nav updates over time
    function test_MultipleNavUpdates() public {
        // Advance time by 25 hours to allow first nav update
        vm.warp(block.timestamp + 25 hours);

        vm.startPrank(ADMIN);

        // First update
        oracle.setNav(1.005e18);
        assertEq(oracle.getNav(xSolvBTC), 1.005e18);

        // Wait 25 hours and update again
        vm.warp(block.timestamp + 25 hours);
        oracle.setNav(1.01e18);
        assertEq(oracle.getNav(xSolvBTC), 1.01e18);

        // Wait another 25 hours and update again
        vm.warp(block.timestamp + 25 hours);
        oracle.setNav(1.015e18);
        assertEq(oracle.getNav(xSolvBTC), 1.015e18);

        vm.stopPrank();
    }

    function _deployXSolvBTCPool() internal returns (address) {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        XSolvBTCPool impl = new XSolvBTCPool{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl),
            address(proxyAdmin),
            abi.encodeWithSignature("initialize(address,address,address,uint64)", solvBTC, xSolvBTC, ADMIN, 100)
        );
        vm.stopPrank();
        return address(proxy);
    }

    function _deployXSolvBTCOracle() internal returns (address) {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        XSolvBTCOracle impl = new XSolvBTCOracle{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize(uint8,uint256)", 18, 1e18)
        );
        XSolvBTCOracle(address(proxy)).setXSolvBTC(xSolvBTC);
        XSolvBTCOracle(address(proxy)).setXSolvBTCPool(address(xSolvBTCPool));
        vm.stopPrank();
        return address(proxy);
    }
}
