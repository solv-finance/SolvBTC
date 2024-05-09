// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SftWrappedToken.sol";

contract XBTC is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function decimals() public pure override returns (uint8) {
        return 8;
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract SolvBTCTest is Test {

    string internal constant TOKEN_NAME = "SolvBTC";
    string internal constant TOKEN_SYMBOL = "SolvBTC";

    XBTC public xbtc;
    SolvBTC public solvBTC;

    address public admin;
    address public user;

    function setUp() public virtual {
        admin = makeAddr("admin");
        user = makeAddr("user");

        xbtc = new XBTC("XBTC", "XBTC");

        ProxyAdmin proxyAdmin = new ProxyAdmin(address(admin));
        SolvBTC solvBTCImpl = new SolvBTC();
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(solvBTCImpl), 
            address(proxyAdmin), 
            abi.encodeWithSignature("initialize(string,string,address)", "SolvBTC", "SolvBTC", address(xbtc))
        );
        solvBTC = SolvBTC(address(proxy));

        vm.startPrank(user);
        xbtc.mint(address(user), 10 * 1e8);
        vm.stopPrank();
    }

    function test_InitialStatusForSolvBTC() public  {
        assertEq(solvBTC.underlyingAsset(), address(xbtc));
    }

    function test_MintSolvBTC() public {
        vm.startPrank(user);        
        uint256 userXbtcBalanceBefore = xbtc.balanceOf(address(user));
        uint256 userSolvBtcBalanceBefore = solvBTC.balanceOf(address(user));
        uint256 vaultXbtcBalanceBefore = xbtc.balanceOf(address(solvBTC));
        uint256 solvBtcTotalSupplyBefore = solvBTC.totalSupply();

        xbtc.approve(address(solvBTC), 1e8);
        solvBTC.mint(1e8);

        uint256 userXbtcBalanceAfter = xbtc.balanceOf(address(user));
        uint256 userSolvBtcBalanceAfter = solvBTC.balanceOf(address(user));
        uint256 vaultXbtcBalanceAfter = xbtc.balanceOf(address(solvBTC));
        uint256 solvBtcTotalSupplyAfter = solvBTC.totalSupply();

        assertEq(userXbtcBalanceBefore - userXbtcBalanceAfter, 1e8);
        assertEq(vaultXbtcBalanceAfter - vaultXbtcBalanceBefore, 1e8);
        assertEq(userSolvBtcBalanceAfter - userSolvBtcBalanceBefore, 1e18);
        assertEq(solvBtcTotalSupplyAfter - solvBtcTotalSupplyBefore, 1e18);
        vm.stopPrank();
    }

    function test_BurnSolvBTC() public {
        vm.startPrank(user);        
        xbtc.approve(address(solvBTC), 1e8);
        solvBTC.mint(1e8);

        uint256 userXbtcBalanceBefore = xbtc.balanceOf(address(user));
        uint256 userSolvBtcBalanceBefore = solvBTC.balanceOf(address(user));
        uint256 vaultXbtcBalanceBefore = xbtc.balanceOf(address(solvBTC));
        uint256 solvBtcTotalSupplyBefore = solvBTC.totalSupply();

        solvBTC.burn(1e18);
        uint256 userXbtcBalanceAfter = xbtc.balanceOf(address(user));
        uint256 userSolvBtcBalanceAfter = solvBTC.balanceOf(address(user));
        uint256 vaultXbtcBalanceAfter = xbtc.balanceOf(address(solvBTC));
        uint256 solvBtcTotalSupplyAfter = solvBTC.totalSupply();

        assertEq(userXbtcBalanceAfter - userXbtcBalanceBefore, 1e8);
        assertEq(vaultXbtcBalanceBefore - vaultXbtcBalanceAfter, 1e8);
        assertEq(userSolvBtcBalanceBefore - userSolvBtcBalanceAfter, 1e18);
        assertEq(solvBtcTotalSupplyBefore - solvBtcTotalSupplyAfter, 1e18);
        vm.stopPrank();
    }

    function test_RevertWhenMintZeroAmount() public {
        vm.startPrank(user);        
        xbtc.approve(address(solvBTC), 1e8);
        vm.expectRevert("SolvBTC: invalid amount");
        solvBTC.mint(0);
        vm.stopPrank();
    }

    function test_RevertWhenMintNotPassBalanceCheck() public {
        vm.startPrank(user);
        xbtc.approve(address(solvBTC), 2e8);
        solvBTC.mint(1e8);

        vm.mockCall(address(xbtc), abi.encodeWithSignature("balanceOf(address)", address(solvBTC)), abi.encode(1e8 - 1));
        vm.expectRevert("SolvBTC: balance check error");
        solvBTC.mint(1e8);
        vm.stopPrank();
    }

    function test_RevertWhenBurnZeroAmount() public {
        vm.startPrank(user);        
        xbtc.approve(address(solvBTC), 1e8);
        solvBTC.mint(1e8);
        vm.expectRevert("SolvBTC: invalid amount");
        solvBTC.burn(0);
        vm.stopPrank();
    }

    function test_RevertWhenBurnNotPassBalanceCheck() public {
        vm.startPrank(user);
        xbtc.approve(address(solvBTC), 2e8);
        solvBTC.mint(2e8);

        vm.mockCall(address(xbtc), abi.encodeWithSignature("balanceOf(address)", address(solvBTC)), abi.encode(1e8 - 1));
        vm.expectRevert("SolvBTC: balance check error");
        solvBTC.burn(1e8);
        vm.stopPrank();
    }

}