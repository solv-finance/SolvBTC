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
    address internal constant WRAPPED_SFT_ADDRESS = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32; //for arbitrum
    uint256 internal constant WRAPPED_SFT_SLOT = 5310353805259224968786693768403624884928279211848504288200646724372830798580;
    address internal constant NAV_ORACLE_ADDRESS = 0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD;

    uint256 internal constant SFT_ID_1 = 2144;
    uint256 internal constant SFT_ID_2 = 2145;
    uint256 internal constant SFT_ID_OF_ANOTHER_SLOT = 2146;

    address public admin = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;
    address public governor = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;
    address public user = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

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

        vm.startPrank(user);
        _approveSftId(address(swt), SFT_ID_1);
        _approveSftId(address(swt), SFT_ID_2);
        vm.stopPrank();
    }

    /** Test for Initial Transfer/Mint when `holdingValueSftId == 0` */

    function test_InitialTransferWithId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        _safeTransferSftId(user, address(swt), SFT_ID_1);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance);
        vm.stopPrank();
    }

    function test_InitialTransferWithValue() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        _transferSftValueToAddress(SFT_ID_1, address(swt), sft1Balance);
        
        uint256 newSftId = _getLastSftIdOwned(address(swt));
        assertNotEq(newSftId, SFT_ID_1);
        assertEq(swt.holdingValueSftId(), newSftId);
        assertEq(swt.balanceOf(user), sft1Balance);
        assertEq(_getSftOwner(SFT_ID_1), user);
        assertEq(_getSftOwner(newSftId), address(swt));
        assertEq(_getSftBalance(SFT_ID_1), 0);
        assertEq(_getSftBalance(newSftId), sft1Balance);
        vm.stopPrank();
    }

    function test_InitialMintWithAllValue() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        swt.mint(SFT_ID_1, sft1Balance);
        
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance);
        vm.stopPrank();
    }

    function test_InitialMintWithPartialValue() public virtual {
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

    /** Test for Non-Initial Transfer/Mint when `holdingValueSftId != 0` */

    function test_NonInitialTransferWithId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        _safeTransferSftId(user, address(swt), SFT_ID_2);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), address(swt));
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(_getSftBalance(SFT_ID_2), 0);
        vm.stopPrank();
    }

    function test_NonInitialTransferWithValue() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        _transferSftValueToId(SFT_ID_2, swt.holdingValueSftId(), sft2Balance);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(_getSftBalance(SFT_ID_2), 0);
        vm.stopPrank();
    }

    function test_NonInitialMintWithAllValue() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        swt.mint(SFT_ID_2, sft2Balance);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), address(swt));
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(_getSftBalance(SFT_ID_2), 0);
        vm.stopPrank();
    }

    function test_NonInitialMintWithPartialValue() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        uint256 mintValue = sft2Balance / 4;
        swt.mint(SFT_ID_2, mintValue);

        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + mintValue);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(SFT_ID_2), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + mintValue);
        assertEq(_getSftBalance(SFT_ID_2), sft2Balance - mintValue);
        vm.stopPrank();
    }

    /** Test for Burn */

    function test_BurnWithGivenSftId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        uint256 burnValue = sft1Balance / 4;
        _safeTransferSftId(user, address(swt), SFT_ID_1);
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
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        uint256 toSftId = swt.burn(burnValue, 0);

        assertNotEq(toSftId, SFT_ID_1);
        assertNotEq(toSftId, SFT_ID_2);
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
        uint256 burnValue1 = sft1Balance / 4;
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        _safeTransferSftId(user, address(swt), SFT_ID_2);
        uint256 toSftId1 = swt.burn(burnValue1, 0);

        assertEq(toSftId1, SFT_ID_2);
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance - burnValue1);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(toSftId1), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance - burnValue1);
        assertEq(_getSftBalance(toSftId1), burnValue1);

        // now the holding empty sft ids is blank again
        uint256 burnValue2 = sft1Balance / 2;
        uint256 toSftId2 = swt.burn(burnValue2, 0);
        assertNotEq(toSftId2, SFT_ID_1);
        assertNotEq(toSftId2, SFT_ID_2);
        assertNotEq(toSftId2, toSftId1);
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        assertEq(swt.balanceOf(user), sft1Balance + sft2Balance - burnValue1 - burnValue2);
        assertEq(_getSftOwner(SFT_ID_1), address(swt));
        assertEq(_getSftOwner(toSftId2), user);
        assertEq(_getSftBalance(SFT_ID_1), sft1Balance + sft2Balance - burnValue1 - burnValue2);
        assertEq(_getSftBalance(toSftId2), burnValue2);
        vm.stopPrank();
    }

    /** Exception Test */

    function test_RevertWhenTransferIdOfInvalidSlot() public virtual {
        vm.startPrank(user);
        vm.expectRevert("SftWrappedToken: unreceivable slot");
        _safeTransferSftId(user, address(swt), SFT_ID_OF_ANOTHER_SLOT);
        vm.stopPrank();
    }

    function test_RevertWhenTransferValueOfInvalidSlot() public virtual {
        vm.startPrank(user);
        uint256 sftBalance = _getSftBalance(SFT_ID_OF_ANOTHER_SLOT);
        vm.expectRevert("SftWrappedToken: unreceivable slot");
        _transferSftValueToAddress(SFT_ID_OF_ANOTHER_SLOT, address(swt), sftBalance);
        vm.stopPrank();
    }

    function test_RevertWhenTransferValueToNonHoldingValueSftId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        _transferSftValueToAddress(SFT_ID_1, address(swt), sft1Balance / 2);

        uint256 sft2Balance = _getSftBalance(SFT_ID_2);
        vm.expectRevert("SftWrappedToken: not holding value sft id");
        _transferSftValueToAddress(SFT_ID_2, address(swt), sft2Balance);

        _safeTransferSftId(user, address(swt), SFT_ID_1);
        vm.expectRevert("SftWrappedToken: not holding value sft id");
        _transferSftValueToId(SFT_ID_2, SFT_ID_1, sft2Balance);
        vm.stopPrank();
    }

    function test_RevertWhenDirectlyCallOnERC3525ReceivedFunction() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        vm.expectRevert("SftWrappedToken: only wrapped sft");
        swt.onERC3525Received(user, SFT_ID_1, SFT_ID_2, sft1Balance, "");
        vm.stopPrank();
    }

    function test_RevertWhenDirectlyCallOnERC721ReceivedFunction() public virtual {
        vm.startPrank(user);
        vm.expectRevert("SftWrappedToken: only wrapped sft");
        swt.onERC721Received(user, user, SFT_ID_1, "");
        vm.stopPrank();
    }

    function test_RevertWhenBurnWithZeroAmount() public virtual {
        vm.startPrank(user);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        vm.expectRevert("SftWrappedToken: burn amount cannot be 0");
        swt.burn(0, SFT_ID_2);
        vm.stopPrank();
    }

    function test_RevertWhenBurnWithSftIdNotOwned() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        vm.expectRevert("SftWrappedToken: not sft owner");
        swt.burn(sft1Balance, SFT_ID_1);
        vm.stopPrank();
    }

    function test_RevertWhenBurnWithSftIdOfInvalidSlot() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = _getSftBalance(SFT_ID_1);
        _safeTransferSftId(user, address(swt), SFT_ID_1);
        vm.expectRevert("SftWrappedToken: slot does not match");
        swt.burn(sft1Balance, SFT_ID_OF_ANOTHER_SLOT);
        vm.stopPrank();
    }

    function _approveSftId(address _spender, uint256 _sftId) internal virtual {
        (bool success, ) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _sftId));
        require(success, "approve sft id failed");
    }

    function _safeTransferSftId(address _from, address _to, uint256 _sftId) internal virtual {
        (bool success, ) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", _from, _to, _sftId));
        require(success, "safe transfer sft id failed");
    }

    function _transferSftValueToId(uint256 _fromSftId, uint256 _toSftId, uint256 _transferValue) internal virtual {
        (bool success, ) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("transferFrom(uint256,uint256,uint256)", _fromSftId, _toSftId, _transferValue));
        require(success, "safe transfer sft value to id failed");
    }

    function _transferSftValueToAddress(uint256 _fromSftId, address _to, uint256 _transferValue) internal virtual {
        (bool success, ) = WRAPPED_SFT_ADDRESS.call(abi.encodeWithSignature("transferFrom(uint256,address,uint256)", _fromSftId, _to, _transferValue));
        require(success, "safe transfer sft value to address failed");
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