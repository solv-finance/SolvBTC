// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrappedTokenFactory.sol";
import "../contracts/SftWrappedToken.sol";

contract SftWrappedTokenTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "SWT RWADemo";
    string internal constant TOKEN_NAME = "SftWrappedToken RWADemo";
    string internal constant TOKEN_SYMBOL = "SWT-RWADemo";
    address internal constant WRAPPED_SFT_ADDRESS = 0x6089795791F539d664F403c4eFF099F48cE17C75;
    uint256 internal constant WRAPPED_SFT_SLOT = 94872245356118649870025069682337571253044538568877833354046341235689653624276;
    address internal constant NAV_ORACLE_ADDRESS = 0x18937025Dffe1b5e9523aa35dEa0EE55dae9D675;

    uint256 internal constant SFT_ID_1 = 272;
    uint256 internal constant SFT_ID_2 = 273;

    address public admin;
    address public governor;
    address public user;

    SftWrappedTokenFactory public factory;
    SftWrappedToken public swt;

    function setUp() public virtual {
        admin = vm.envAddress("ADMIN");
        governor = vm.envAddress("GOVERNOR");
        user = vm.envAddress("USER");

        vm.startPrank(admin);
        factory = new SftWrappedTokenFactory(governor);
        SftWrappedToken swtImpl = new SftWrappedToken();
        factory.setImplementation(PRODUCT_TYPE, address(swtImpl));
        factory.deployBeacon(PRODUCT_TYPE);
        swt = SftWrappedToken(
            factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS)
        );
        vm.stopPrank();

        vm.startPrank(user);
        _approveSftId(address(swt), SFT_ID_1);
        _approveSftId(address(swt), SFT_ID_2);
        vm.stopPrank();
    }

    function test_MintWithAllValueForTheFirstTime() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        swt.mint(SFT_ID_1, sft1Balance);
        
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        vm.stopPrank();
    }

    function test_MintWithPartialValueForTheFirstTime() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 mintValue = sft1Balance / 4;
        swt.mint(SFT_ID_1, mintValue);
        uint256 newSftId = _getLastSftIdOwned(address(swt));

        assertEq(swt.holdingValueSftId(), newSftId);
        assertEq(swt.balanceOf(user), mintValue);
        assertEq(_getSftOwner(newSftId), address(swt));
        assertEq(_getSftOwner(SFT_ID_1), user);
        assertEq(_getSftBalance(newSftId), mintValue);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance - mintValue);
        vm.stopPrank();
    }

    function test_MintWithAllValueForNotFirstTime() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        swt.mint(SFT_ID_1, sft1Balance);
        swt.mint(SFT_ID_2, sft2Balance);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), address(swt));
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(_getSftBalance(SFT_ID_2), 0);

        vm.stopPrank();
    }

    function test_MintWithPartialValueForNotFirstTime() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        uint256 mintValue = sft2Balance / 4;
        swt.mint(SFT_ID_1, sft1Balance);
        swt.mint(SFT_ID_2, mintValue);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + mintValue);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + mintValue);
        assertEq(_getSftBalance(SFT_ID_2), sft2Balance - mintValue);

        vm.stopPrank();
    }

    function test_BurnWithGivenSftId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        uint256 burnValue = sft1Balance / 4;
        swt.mint(SFT_ID_1, sft1Balance);
        uint256 toSftId = swt.burn(burnValue, SFT_ID_2);

        assertEq(toSftId, SFT_ID_2);
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance - burnValue);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance - burnValue);
        assertEq(_getSftBalance(SFT_ID_2), sft2Balance + burnValue);
        vm.stopPrank();
    }

    function test_BurnWithoutGivenSftIdWhenHoldingEmptySftIdsIsBlank() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        uint256 burnValue = sft1Balance / 4;
        swt.mint(SFT_ID_1, sft1Balance);
        uint256 toSftId = swt.burn(burnValue, 0);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance - burnValue);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), user);
        assertEq(_getSftOwner(toSftId), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance - burnValue);
        assertEq(_getSftBalance(SFT_ID_2), sft2Balance);
        assertEq(_getSftBalance(toSftId), burnValue);
        vm.stopPrank();
    }

    function test_BurnWithoutGivenSftIdWhenHoldingEmptySftIdsIsNotBlank() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        uint256 burnValue = sft1Balance / 4;
        swt.mint(SFT_ID_1, sft1Balance);
        swt.mint(SFT_ID_2, sft2Balance);
        uint256 toSftId = swt.burn(burnValue, 0);

        assertEq(toSftId, SFT_ID_2);
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance - burnValue);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance - burnValue);
        assertEq(_getSftBalance(SFT_ID_2), burnValue);
        vm.stopPrank();
    }

    function _approveSftId(address _spender, uint256 _sftId) internal virtual {
        (bool success, ) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _sftId));
        require(success, "approve sft id failed");
    }

    function _getSftBalance(uint256 _sftId) internal virtual returns (uint256 balance) {
        (bool success, bytes memory result) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("balanceOf(uint256)", _sftId));
        require(success, "get sft balance failed");
        (balance) = abi.decode(result, (uint256));
    }

    function _getSftOwner(uint256 _sftId) internal virtual returns (address owner) {
        (bool success, bytes memory result) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("ownerOf(uint256)", _sftId));
        require(success, "get sft owner failed");
        (owner) = abi.decode(result, (address));
    }

    function _getLastSftIdOwned(address _owner) internal virtual returns (uint256 sftId) {
        (, bytes memory result1) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("balanceOf(address)", _owner));
        (uint256 balance) = abi.decode(result1, (uint256));
        (bool success, bytes memory result) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", _owner, balance - 1));
        require(success, "get last sft if owned failed");
        (sftId) = abi.decode(result, (uint256));
    }

}