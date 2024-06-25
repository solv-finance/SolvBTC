// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrapRouter.sol";

contract SftWrapRouterTest is Test {

    string internal constant PRODUCT_TYPE = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME = "SWT RWADemo";
    string internal constant TOKEN_NAME = "SftWrappedToken RWADemo";
    string internal constant TOKEN_SYMBOL = "SWT-RWADemo";

    address internal constant WRAPPED_SFT_ADDRESS = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32; // for arbitrum
    uint256 internal constant WRAPPED_SFT_SLOT = 5310353805259224968786693768403624884928279211848504288200646724372830798580; // GMX V2 USDC - A
    bytes32 internal constant WRAPPED_SFT_POOL_ID = 0xe037ef7b5f74bf3c988d8ae8ab06ad34643749ba9d217092297241420d600fce; // GMX V2 USDC - A
    address internal constant REDEMPTION_SFT_ADDRESS = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address internal constant MARKET_ADDRESS = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address internal constant NAV_ORACLE_ADDRESS = 0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD;
    address internal constant USDC_ADDRESS = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    uint256 internal constant SFT_ID_1 = 2144;
    uint256 internal constant SFT_ID_2 = 2145;
    uint256 internal constant SFT_ID_OF_ANOTHER_SLOT = 2146;

    address public admin = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;
    address public governor = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;
    address public user = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    SftWrappedTokenFactory public factory;
    SftWrappedToken public swt;
    SftWrapRouter public router;

    function setUp() public virtual {
        vm.startPrank(admin);
        factory = new SftWrappedTokenFactory(governor);
        SftWrappedToken swtImpl = new SftWrappedToken();
        factory.setImplementation(PRODUCT_TYPE, address(swtImpl));
        factory.deployBeacon(PRODUCT_TYPE);
        swt = SftWrappedToken(
            factory.deployProductProxy(PRODUCT_TYPE, PRODUCT_NAME, TOKEN_NAME, TOKEN_SYMBOL, WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT, NAV_ORACLE_ADDRESS)
        );
        router = new SftWrapRouter();
        router.initialize(governor, MARKET_ADDRESS, address(factory));
        vm.stopPrank();
    }

    function test_InitialStatus() public virtual {
        assertEq(router.admin(), admin);
        assertEq(router.governor(), governor);
        assertEq(router.openFundMarket(), MARKET_ADDRESS);
        assertEq(router.sftWrappedTokenFactory(), address(factory));
    }

    function test_OnERC721Received_FirstStake() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);

        IERC3525(WRAPPED_SFT_ADDRESS).safeTransferFrom(user, address(router), SFT_ID_1);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), sft1Balance);
        assertEq(router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT), 0);
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        vm.stopPrank();
    }

    function test_OnERC721Received_NotFirstStake() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        uint256 sft2Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2);

        IERC3525(WRAPPED_SFT_ADDRESS).safeTransferFrom(user, address(router), SFT_ID_1);
        IERC3525(WRAPPED_SFT_ADDRESS).safeTransferFrom(user, address(router), SFT_ID_2);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance + sft2Balance);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_2), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2), 0);
        assertEq(router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT), 0);
        assertEq(swt.holdingValueSftId(), SFT_ID_1);
        vm.stopPrank();
    }

    function test_OnERC3525Received_FirstStake() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);

        IERC3525(WRAPPED_SFT_ADDRESS).transferFrom(SFT_ID_1, address(router), sft1Balance);
        uint256 routerHoldingSftId = router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), user);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), sft1Balance);
        vm.stopPrank();
    }

    function test_OnERC3525Received_NotFirstStake() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        uint256 sft2Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2);

        IERC3525(WRAPPED_SFT_ADDRESS).transferFrom(SFT_ID_1, address(router), sft1Balance);
        uint256 routerHoldingSftId = router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();
        IERC3525(WRAPPED_SFT_ADDRESS).transferFrom(SFT_ID_2, routerHoldingSftId, sft2Balance);

        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance + sft2Balance);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), user);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_2), user);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), sft1Balance + sft2Balance);
        vm.stopPrank();
    }

    function test_FirstStakeWithAllValue() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);

        IERC3525(WRAPPED_SFT_ADDRESS).approve(address(router), SFT_ID_1);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, sft1Balance);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        uint256 routerHoldingSftId = router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance);
        assertEq(routerHoldingSftId, 0);
        assertEq(swtHoldingValueSftId, SFT_ID_1);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), sft1Balance);
        vm.stopPrank();
    }

    function test_FirstStakeWithPartialValue() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        uint256 stakeValue = sft1Balance / 4;

        IERC3525(WRAPPED_SFT_ADDRESS).approve(SFT_ID_1, address(router), stakeValue);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, stakeValue);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        uint256 routerHoldingSftId = router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, stakeValue);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), user);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), sft1Balance - stakeValue);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), stakeValue);
        vm.stopPrank();
    }

    function test_NonFirstStakeWithAllValue() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        uint256 sft2Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2);

        IERC3525(WRAPPED_SFT_ADDRESS).approve(address(router), SFT_ID_1);
        IERC3525(WRAPPED_SFT_ADDRESS).approve(address(router), SFT_ID_2);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, sft1Balance);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_2, sft2Balance);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        uint256 routerHoldingSftId = router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance + sft2Balance);
        assertEq(routerHoldingSftId, 0);
        assertEq(swtHoldingValueSftId, SFT_ID_1);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_2), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), sft1Balance + sft2Balance);
        vm.stopPrank();
    }

    function test_NonFirstStakeWithPartialValue() public virtual {
        vm.startPrank(user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        uint256 stakeValue1 = sft1Balance / 4;
        uint256 stakeValue2 = sft1Balance / 2;

        IERC3525(WRAPPED_SFT_ADDRESS).approve(SFT_ID_1, address(router), stakeValue1 + stakeValue2);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, stakeValue1);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, stakeValue2);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        uint256 routerHoldingSftId = router.holdingSftIds(WRAPPED_SFT_ADDRESS, WRAPPED_SFT_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, stakeValue1 + stakeValue2);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(SFT_ID_1), user);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1), sft1Balance - stakeValue1 - stakeValue2);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), stakeValue1 + stakeValue2);
        vm.stopPrank();
    }

    function test_UnstakeWhenGivenSftId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        IERC3525(WRAPPED_SFT_ADDRESS).approve(address(router), SFT_ID_1);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, sft1Balance);

        uint256 swtHoldingValueSftId = swt.holdingValueSftId();
        uint256 swtHoldingValueBefore = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 sft2BalanceBefore = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2);
        uint256 unstakeAmount = swtBalanceBefore / 4;

        uint256 slot = IERC3525(WRAPPED_SFT_ADDRESS).slotOf(SFT_ID_2);
        _erc20Approve(address(swt), address(router), unstakeAmount);
        uint256 toSftId = router.unstake(address(swt), unstakeAmount, WRAPPED_SFT_ADDRESS, slot, SFT_ID_2);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);

        assertEq(toSftId, SFT_ID_2);
        assertEq(swtBalanceBefore - swtBalanceAfter, unstakeAmount);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_2), sft2BalanceBefore + unstakeAmount);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), swtHoldingValueBefore - unstakeAmount);
        vm.stopPrank();
    }

    function test_UnstakeWhenNotGivenSftId() public virtual {
        vm.startPrank(user);
        uint256 sft1Balance = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(SFT_ID_1);
        IERC3525(WRAPPED_SFT_ADDRESS).approve(address(router), SFT_ID_1);
        router.stake(WRAPPED_SFT_ADDRESS, SFT_ID_1, sft1Balance);

        uint256 swtHoldingValueSftId = swt.holdingValueSftId();
        uint256 swtHoldingValueBefore = IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 unstakeAmount = swtBalanceBefore / 4;

        uint256 slot = IERC3525(WRAPPED_SFT_ADDRESS).slotOf(SFT_ID_1);
        _erc20Approve(address(swt), address(router), unstakeAmount);
        uint256 toSftId = router.unstake(address(swt), unstakeAmount, WRAPPED_SFT_ADDRESS, slot, 0);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);

        assertEq(swtBalanceBefore - swtBalanceAfter, unstakeAmount);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(toSftId), unstakeAmount);
        assertEq(IERC3525(WRAPPED_SFT_ADDRESS).balanceOf(swtHoldingValueSftId), swtHoldingValueBefore - unstakeAmount);
        vm.stopPrank();
    }

    function test_CreateSubscription() public virtual {
        vm.startPrank(user);
        uint256 currencyBalanceBefore = _getErc20Balance(USDC_ADDRESS, user);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 subscribeCurrencyAmount = 100e6;

        ERC20(USDC_ADDRESS).approve(address(router), subscribeCurrencyAmount);
        _erc20Approve(USDC_ADDRESS, address(router), subscribeCurrencyAmount);
        router.createSubscription(WRAPPED_SFT_POOL_ID, subscribeCurrencyAmount);
        uint256 currencyBalanceAfter = _getErc20Balance(USDC_ADDRESS, user);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);

        assertEq(currencyBalanceBefore - currencyBalanceAfter, subscribeCurrencyAmount);
        uint256 nav = _getSubscribeNav(WRAPPED_SFT_POOL_ID, block.timestamp);
        uint256 dueSwtAmount = subscribeCurrencyAmount * (10 ** _getErc20Decimals(address(swt))) / nav;
        assertEq(swtBalanceAfter - swtBalanceBefore, dueSwtAmount);
        vm.stopPrank();
    }

    function test_CreateRedemption() public virtual {
        vm.startPrank(user);
        uint256 subscribeCurrencyAmount = 100e6;
        _erc20Approve(USDC_ADDRESS, address(router), subscribeCurrencyAmount);
        router.createSubscription(WRAPPED_SFT_POOL_ID, subscribeCurrencyAmount);

        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        uint256 redeemAmount = 20 ether;
        _erc20Approve(address(swt), address(router), redeemAmount);
        router.createRedemption(WRAPPED_SFT_POOL_ID, redeemAmount);

        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        assertEq(swtBalanceBefore - swtBalanceAfter, redeemAmount);

        uint256 redemptionId = _getLastSftIdOwned(REDEMPTION_SFT_ADDRESS, user);
        uint256 redemptionBalance = _getSftBalance(REDEMPTION_SFT_ADDRESS, redemptionId);
        assertEq(redemptionBalance, redeemAmount);
        vm.stopPrank();
    }

    function test_CancelRedemption() public virtual {
        vm.startPrank(user);
        uint256 subscribeCurrencyAmount = 100e6;
        _erc20Approve(USDC_ADDRESS, address(router), subscribeCurrencyAmount);
        router.createSubscription(WRAPPED_SFT_POOL_ID, subscribeCurrencyAmount);

        uint256 redeemAmount = 20 ether;
        _erc20Approve(address(swt), address(router), redeemAmount);
        router.createRedemption(WRAPPED_SFT_POOL_ID, redeemAmount);
        uint256 redemptionId = _getLastSftIdOwned(REDEMPTION_SFT_ADDRESS, user);

        uint256 swtBalanceBefore = _getErc20Balance(address(swt), user);
        _approveSftId(REDEMPTION_SFT_ADDRESS, address(router), redemptionId);
        router.cancelRedemption(WRAPPED_SFT_POOL_ID, redemptionId);

        uint256 swtBalanceAfter = _getErc20Balance(address(swt), user);
        assertEq(swtBalanceAfter - swtBalanceBefore, redeemAmount);

        vm.expectRevert("ERC3525: invalid token ID");
        IERC3525(REDEMPTION_SFT_ADDRESS).ownerOf(redemptionId);
        vm.stopPrank();
    }

    function _erc20Approve(address _erc20, address _spender, uint256 _allowance) internal virtual {
        (bool success, ) = _erc20.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _allowance));
        require(success, "erc20 approve failed");
    }

    function _getErc20Decimals(address _erc20) internal virtual returns (uint8 decimals) {
        (bool success, bytes memory result) = _erc20.call(abi.encodeWithSignature("decimals()"));
        require(success, "get erc20 decimals failed");
        (decimals) = abi.decode(result, (uint8));
    }

    function _getErc20Balance(address _erc20, address _owner) internal virtual returns (uint256 balance) {
        (bool success, bytes memory result) = _erc20.call(abi.encodeWithSignature("balanceOf(address)", _owner));
        require(success, "get erc20 balance failed");
        (balance) = abi.decode(result, (uint256));
    }


    function _getSubscribeNav(bytes32 _poolId, uint256 _timestamp) internal virtual returns (uint256 nav) {
        (bool success, bytes memory result) = NAV_ORACLE_ADDRESS.call(abi.encodeWithSignature("getSubscribeNav(bytes32,uint256)", _poolId, _timestamp));
        require(success, "get nav failed");
        (nav, ) = abi.decode(result, (uint256, uint256));
    }


    function _approveSftId(address _sft, address _spender, uint256 _sftId) internal virtual {
        (bool success, ) = _sft.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _sftId));
        require(success, "approve sft id failed");
    }

    function _approveSftValue(address _sft, address _spender, uint256 _sftId, uint256 _allowance) internal virtual {
        (bool success, ) = _sft.call(abi.encodeWithSignature("approve(uint256,address,uint256)", _sftId, _spender, _allowance));
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

    function _getSftBalance(address _sft, uint256 _sftId) internal virtual returns (uint256 balance) {
        (bool success, bytes memory result) = _sft.call(abi.encodeWithSignature("balanceOf(uint256)", _sftId));
        require(success, "get sft balance failed");
        (balance) = abi.decode(result, (uint256));
    }

    function _getSftOwner(address _sft, uint256 _sftId) internal virtual returns (address owner) {
        (bool success, bytes memory result) = _sft.call(abi.encodeWithSignature("ownerOf(uint256)", _sftId));
        require(success, "get sft owner failed");
        (owner) = abi.decode(result, (address));
    }

    function _getLastSftIdOwned(address _sft, address _owner) internal virtual returns (uint256 sftId) {
        (, bytes memory result1) = _sft.call(abi.encodeWithSignature("balanceOf(address)", _owner));
        (uint256 balance) = abi.decode(result1, (uint256));
        (bool success, bytes memory result) = _sft.call(abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", _owner, balance - 1));
        require(success, "get last sft if owned failed");
        (sftId) = abi.decode(result, (uint256));
    }

}