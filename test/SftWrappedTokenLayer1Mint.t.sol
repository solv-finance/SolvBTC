// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrappedTokenFactory.sol";
import "../contracts/SftWrappedToken.sol";

contract SftWrappedTokenLayer1MintTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "SWT RWADemo";
    string internal constant TOKEN_NAME = "SftWrappedToken RWADemo";
    string internal constant TOKEN_SYMBOL = "SWT-RWADemo";
    address internal constant WRAPPED_SFT_ADDRESS = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32; //for arbitrum
    uint256 internal constant WRAPPED_SFT_SLOT = 5310353805259224968786693768403624884928279211848504288200646724372830798580;
    address internal constant NAV_ORACLE_ADDRESS = 0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD;

    address public admin = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;
    address public governor = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address public layer1Minter = 0x3555706fef56a7c496CefBe903Bf0d2AC9e13525;
    address public layer1MintTo = 0xdbb7B1F656c8844cf8311a54937b806b6aF99999;

    SftWrappedTokenFactory public factory;
    SftWrappedToken public swt;

    function setUp() public virtual {
        vm.startPrank(admin);
        factory = new SftWrappedTokenFactory(governor);
        SftWrappedToken swtImpl = new SftWrappedToken();
        factory.setImplementation(PRODUCT_TYPE, address(swtImpl));
        factory.deployBeacon(PRODUCT_TYPE);
        swt = SftWrappedToken(
            factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS)
        );
        vm.stopPrank();
    }

    function test_GetLayer1Minter() public virtual {
        assertEq(swt.layer1Minter(), layer1Minter);
    }

    function test_Layer1Mint() public virtual {
        vm.startPrank(layer1Minter);
        uint256 layer1MintToBalanceBefore = swt.balanceOf(layer1MintTo);
        uint256 totalSupplyBefore = swt.totalSupply();
        uint256 mintAmount = 100 ether;
        swt.layer1Mint(layer1MintTo, mintAmount);
        uint256 layer1MintToBalanceAfter = swt.balanceOf(layer1MintTo);
        uint256 totalSupplyAfter = swt.totalSupply();
        assertEq(layer1MintToBalanceAfter - layer1MintToBalanceBefore, mintAmount);
        assertEq(totalSupplyAfter - totalSupplyBefore, mintAmount);
        vm.stopPrank();
    }

    function test_Layer1Burn() public virtual {
        vm.startPrank(layer1Minter);
        uint256 mintAmount = 100 ether;
        swt.layer1Mint(layer1MintTo, mintAmount);
        uint256 layer1MintToBalanceBefore = swt.balanceOf(layer1MintTo);
        uint256 totalSupplyBefore = swt.totalSupply();
        uint256 burnAmount = 20 ether;
        swt.layer1Burn(layer1MintTo, burnAmount);
        uint256 layer1MintToBalanceAfter = swt.balanceOf(layer1MintTo);
        uint256 totalSupplyAfter = swt.totalSupply();
        assertEq(layer1MintToBalanceBefore - layer1MintToBalanceAfter, burnAmount);
        assertEq(totalSupplyBefore - totalSupplyAfter, burnAmount);
        vm.stopPrank();
    }

    function test_RevertWhenLayer1MintByOthers() public virtual {
        vm.startPrank(layer1MintTo);
        vm.expectRevert("only layer1 minter");
        swt.layer1Mint(layer1MintTo, 100 ether);
        vm.stopPrank();
    }

    function test_RevertWhenLayer1BurnByOthers() public virtual {
        vm.startPrank(layer1Minter);
        swt.layer1Mint(layer1MintTo, 100 ether);
        vm.stopPrank();

        vm.startPrank(layer1MintTo);
        vm.expectRevert("only layer1 minter");
        swt.layer1Burn(layer1MintTo, 20 ether);
        vm.stopPrank();
    }

    function test_RevertWhenOverBurn() public virtual {
        vm.startPrank(layer1Minter);
        swt.layer1Mint(layer1MintTo, 100 ether);
        vm.expectRevert();
        swt.layer1Burn(layer1MintTo, 101 ether);
        vm.stopPrank();
    }

}