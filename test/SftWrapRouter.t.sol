// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/SftWrapRouter.sol";
import "../contracts/SolvBTC.sol";
import "../contracts/SolvBTCMultiAssetPool.sol";

contract MockSolvBTC is SolvBTC {
    function solvBTCMultiAssetPool() public view virtual override returns (address) {
        return 0xC221Bc51373FD7acf3C169205113c7b11108AA11;
    }
}

contract SftWrapRouterTest is Test {

    string internal constant PRODUCT_TYPE_YIELDS = "Solv Yield Market Products";
    string internal constant PRODUCT_NAME_GMXUSDC = "GMX V2 USDC";
    string internal constant TOKEN_NAME_GMXUSDC = "GMX V2 USDC";
    string internal constant TOKEN_SYMBOL_GMXUSDC = "GMX V2 USDC";

    string internal constant PRODUCT_TYPE_SOLVBTC = "Open-end Fund Share Wrapped Token";
    string internal constant PRODUCT_NAME_SOLVBTC = "Solv BTC";

    address internal constant FUND_SFT = 0x22799DAA45209338B7f938edf251bdfD1E6dCB32;
    uint256 internal constant GMXUSDC_SLOT = 5310353805259224968786693768403624884928279211848504288200646724372830798580; // GMX V2 USDC - A
    bytes32 internal constant GMXUSDC_POOL_ID = 0xe037ef7b5f74bf3c988d8ae8ab06ad34643749ba9d217092297241420d600fce; // GMX V2 USDC - A
    
    address internal constant REDEMPTION_SFT_ADDRESS = 0xe9bD233b2b34934Fb83955EC15c2ac48F31A0E8c;
    address internal constant MARKET_ADDRESS = 0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8;
    address internal constant NAV_ORACLE_ADDRESS = 0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD;
    address internal constant USDC_ADDRESS = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    address internal constant SOLVBTC_SFT = 0xD20078BD38AbC1378cB0a3F6F0B359c4d8a7b90E;
    uint256 internal constant SOLVBTC_SLOT = 39475026322910990648776764986670533412889479187054865546374468496663502783148;
    uint256 internal constant SOLVBTC_HOLDING_VALUE_SFT_ID = 72;

    uint256 internal constant SOLVBTC_SFT_ID_1 = 50;
    address internal constant SOLVBTC_SFT_HOLDER_1 = 0x08eb297be45f0AcEfe82529FEF03bCf49D6d28CD;
    uint256 internal constant SOLVBTC_SFT_ID_2 = 85;
    address internal constant SOLVBTC_SFT_HOLDER_2 = 0x0dE2AfF670Dd19394f96Bad9b14a8df11C9a94EB;

    uint256 internal constant GMXBTC_SLOT = 18834720600760682316079182603327587109774167238702271733823387280510631407444;
    uint256 internal GMXBTC_HOLDING_VALUE_SFT_ID;

    uint256 internal constant FUND_SFT_ID_1 = 2144;
    uint256 internal constant FUND_SFT_ID_2 = 2145;
    address internal constant FUND_SFT_HOLDER_1 = 0xd1B4ea4A0e176292D667695FC7674F845009b32E;

    address internal constant ADMIN = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;
    address internal constant GOVERNOR = 0x55C09707Fd7aFD670e82A62FaeE312903940013E;

    SftWrappedToken internal swt;
    SftWrapRouter internal router = SftWrapRouter(0x6Ea88D4D0c4bC06F6A51f427eF295c93e10D0b36);

    SftWrappedTokenFactory internal factory = SftWrappedTokenFactory(0x81a90E44d81D8baFa82D8AD018F1055BB41cF41c);
    SolvBTC internal solvBTC = SolvBTC(0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0);
    SolvBTCMultiAssetPool internal solvBTCMultiAssetPool;
    ProxyAdmin internal proxyAdmin = ProxyAdmin(0xEcb7d6497542093b25835fE7Ad1434ac8b0bce40);

    function setUp() public {
        _deploySftWrappedToken();
        _deploySolvBTCMultiAssetPool();
        _upgradeSolvBTC();
        _setupSolvBTC();
        _setupMultiAssetPool();
        _upgradeRouter();
    }

    function test_RouterInitialStatus() public {
        assertEq(router.admin(), ADMIN);
        assertEq(router.governor(), GOVERNOR);
        assertEq(router.openFundMarket(), MARKET_ADDRESS);
        assertEq(router.sftWrappedTokenFactory(), address(factory));
        assertEq(router.solvBTCMultiAssetPool(), address(solvBTCMultiAssetPool));
    }

    /** Tests for onERC721Received */
    function test_SolvBTC_OnERC721Received_FirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceBefore = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        IERC3525(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER_1, address(router), SOLVBTC_SFT_ID_1);
        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceAfter = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, solvBTCSft1BalanceBefore);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, solvBTCSft1BalanceBefore);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, solvBTCSft1BalanceBefore);
        assertEq(swtBalanceBefore, swtBalanceAfter);
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), address(solvBTCMultiAssetPool));
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT), 0);
        vm.stopPrank();
    }

    function test_SolvBTC_OnERC721Received_NotFirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        IERC3525(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER_2, address(router), SOLVBTC_SFT_ID_2);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceBefore = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);
        IERC3525(SOLVBTC_SFT).safeTransferFrom(SOLVBTC_SFT_HOLDER_1, address(router), SOLVBTC_SFT_ID_1);
        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceAfter = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, solvBTCSft1BalanceBefore);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, solvBTCSft1BalanceBefore);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, solvBTCSft1BalanceBefore);
        assertEq(swtBalanceBefore, swtBalanceAfter);
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), address(solvBTCMultiAssetPool));
        assertEq(solvBTCSft1BalanceAfter, 0);
        assertEq(router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT), 0);
        vm.stopPrank();
    }

    function test_SWT_OnERC721Received_FirstStake() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtTotalSupplyBefore = swt.totalSupply();
        uint256 swtBalanceBefore = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        IERC3525(FUND_SFT).safeTransferFrom(FUND_SFT_HOLDER_1, address(router), FUND_SFT_ID_1);
        uint256 swtTotalSupplyAfter = swt.totalSupply();
        uint256 swtBalanceAfter = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceAfter = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);

        assertEq(swtTotalSupplyAfter - swtTotalSupplyBefore, fundSft1BalanceBefore);
        assertEq(swtBalanceAfter - swtBalanceBefore, fundSft1BalanceBefore);
        assertEq(solvBTCBalanceBefore, solvBTCBalanceAfter);
        assertEq(fundSft1BalanceBefore, fundSft1BalanceAfter);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), address(swt));
        assertEq(router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT), 0);
        assertEq(swt.holdingValueSftId(), FUND_SFT_ID_1);
        vm.stopPrank();
    }

    function test_SWT_OnERC721Received_NotFirstStake() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtTotalSupplyBefore = swt.totalSupply();
        uint256 swtBalanceBefore = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 fundSft2BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2);
        IERC3525(FUND_SFT).safeTransferFrom(FUND_SFT_HOLDER_1, address(router), FUND_SFT_ID_1);
        IERC3525(FUND_SFT).safeTransferFrom(FUND_SFT_HOLDER_1, address(router), FUND_SFT_ID_2);
        uint256 swtTotalSupplyAfter = swt.totalSupply();
        uint256 swtBalanceAfter = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceAfter = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 fundSft2BalanceAfter = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2);

        assertEq(swtTotalSupplyAfter - swtTotalSupplyBefore, fundSft1BalanceBefore + fundSft2BalanceBefore);
        assertEq(swtBalanceAfter - swtBalanceBefore, fundSft1BalanceBefore + fundSft2BalanceBefore);
        assertEq(solvBTCBalanceBefore, solvBTCBalanceAfter);
        assertEq(fundSft1BalanceAfter, fundSft1BalanceBefore + fundSft2BalanceBefore);
        assertEq(fundSft2BalanceAfter, 0);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), address(swt));
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_2), address(swt));
        assertEq(router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT), 0);
        assertEq(swt.holdingValueSftId(), FUND_SFT_ID_1);
        vm.stopPrank();
    }

    /** Tests for onERC3525Received */
    function test_SolvBTC_OnERC3525Received_FirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceBefore = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        uint256 stakeValue = solvBTCSft1BalanceBefore / 4;
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID_1, address(router), stakeValue);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);

        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceAfter = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, stakeValue);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, stakeValue);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, stakeValue);
        assertEq(swtBalanceBefore, swtBalanceAfter);
        assertEq(solvBTCSft1BalanceBefore - solvBTCSft1BalanceAfter, stakeValue);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), SOLVBTC_SFT_HOLDER_1);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(routerHoldingSftId), address(router));
        vm.stopPrank();
    }

    function test_SolvBTC_OnERC3525Received_NotFirstStake() public {
        vm.startPrank(SOLVBTC_SFT_HOLDER_2);
        uint256 solvBTCSft2Balance = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_2);
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID_2, address(router), solvBTCSft2Balance);
        uint256 routerHoldingSftId = router.holdingSftIds(SOLVBTC_SFT, SOLVBTC_SLOT);
        vm.stopPrank();

        vm.startPrank(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCTotalSupplyBefore = solvBTC.totalSupply();
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceBefore = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueBefore = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        uint256 stakeValue = solvBTCSft1BalanceBefore / 4;
        IERC3525(SOLVBTC_SFT).transferFrom(SOLVBTC_SFT_ID_1, routerHoldingSftId, stakeValue);
        uint256 solvBTCTotalSupplyAfter = solvBTC.totalSupply();
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 swtBalanceAfter = swt.balanceOf(SOLVBTC_SFT_HOLDER_1);
        uint256 solvBTCSft1BalanceAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_SFT_ID_1);
        uint256 poolHoldingValueAfter = IERC3525(SOLVBTC_SFT).balanceOf(SOLVBTC_HOLDING_VALUE_SFT_ID);

        assertEq(solvBTCTotalSupplyAfter - solvBTCTotalSupplyBefore, stakeValue);
        assertEq(solvBTCBalanceAfter - solvBTCBalanceBefore, stakeValue);
        assertEq(poolHoldingValueAfter - poolHoldingValueBefore, stakeValue);
        assertEq(swtBalanceBefore, swtBalanceAfter);
        assertEq(solvBTCSft1BalanceBefore - solvBTCSft1BalanceAfter, stakeValue);
        assertEq(IERC3525(SOLVBTC_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(SOLVBTC_SFT_ID_1), SOLVBTC_SFT_HOLDER_1);
        assertEq(IERC3525(SOLVBTC_SFT).ownerOf(routerHoldingSftId), address(router));
        vm.stopPrank();
    }

    function test_SWT_OnERC3525Received_FirstStake() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtTotalSupplyBefore = swt.totalSupply();
        uint256 swtBalanceBefore = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);

        uint256 stakeValue = fundSft1BalanceBefore / 4;
        IERC3525(FUND_SFT).transferFrom(FUND_SFT_ID_1, address(router), stakeValue);
        uint256 routerHoldingSftId = router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        uint256 swtTotalSupplyAfter = swt.totalSupply();
        uint256 swtBalanceAfter = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceAfter = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);

        assertEq(swtTotalSupplyAfter - swtTotalSupplyBefore, stakeValue);
        assertEq(swtBalanceAfter - swtBalanceBefore, stakeValue);
        assertEq(solvBTCBalanceBefore, solvBTCBalanceAfter);
        assertEq(fundSft1BalanceBefore - fundSft1BalanceAfter, stakeValue);
        assertEq(IERC3525(FUND_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), stakeValue);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), FUND_SFT_HOLDER_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(FUND_SFT).ownerOf(swtHoldingValueSftId), address(swt));
        vm.stopPrank();
    }

    function test_SWT_OnERC3525Received_NotFirstStake() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtTotalSupplyBefore = swt.totalSupply();
        uint256 swtBalanceBefore = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceBefore = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 fundSft2BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2);

        uint256 stakeValue1 = fundSft1BalanceBefore;
        uint256 stakeValue2 = fundSft2BalanceBefore / 4;
        IERC3525(FUND_SFT).transferFrom(FUND_SFT_ID_1, address(router), stakeValue1);
        uint256 routerHoldingSftId = router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();
        IERC3525(FUND_SFT).transferFrom(FUND_SFT_ID_2, routerHoldingSftId, stakeValue2);

        uint256 swtTotalSupplyAfter = swt.totalSupply();
        uint256 swtBalanceAfter = swt.balanceOf(FUND_SFT_HOLDER_1);
        uint256 solvBTCBalanceAfter = solvBTC.balanceOf(FUND_SFT_HOLDER_1);
        uint256 fundSft1BalanceAfter = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 fundSft2BalanceAfter = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2);

        assertEq(swtTotalSupplyAfter - swtTotalSupplyBefore, stakeValue1 + stakeValue2);
        assertEq(swtBalanceAfter - swtBalanceBefore, stakeValue1 + stakeValue2);
        assertEq(solvBTCBalanceBefore, solvBTCBalanceAfter);
        assertEq(fundSft1BalanceBefore - fundSft1BalanceAfter, stakeValue1);
        assertEq(fundSft2BalanceBefore - fundSft2BalanceAfter, stakeValue2);
        assertEq(IERC3525(FUND_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), stakeValue1 + stakeValue2);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), FUND_SFT_HOLDER_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_2), FUND_SFT_HOLDER_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(FUND_SFT).ownerOf(swtHoldingValueSftId), address(swt));
        vm.stopPrank();
    }

    /** Tests for stake function */



    function test_FirstStakeWithAllValue() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);

        IERC3525(FUND_SFT).approve(address(router), FUND_SFT_ID_1);
        router.stake(FUND_SFT, FUND_SFT_ID_1, sft1Balance);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 routerHoldingSftId = router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance);
        assertEq(routerHoldingSftId, 0);
        assertEq(swtHoldingValueSftId, FUND_SFT_ID_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), address(swt));
        assertEq(IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1), sft1Balance);
        vm.stopPrank();
    }

    function test_FirstStakeWithPartialValue() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 stakeValue = sft1Balance / 4;

        IERC3525(FUND_SFT).approve(FUND_SFT_ID_1, address(router), stakeValue);
        router.stake(FUND_SFT, FUND_SFT_ID_1, stakeValue);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 routerHoldingSftId = router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, stakeValue);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), FUND_SFT_HOLDER_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(FUND_SFT).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1), sft1Balance - stakeValue);
        assertEq(IERC3525(FUND_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), stakeValue);
        vm.stopPrank();
    }

    function test_NonFirstStakeWithAllValue() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 sft2Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2);

        IERC3525(FUND_SFT).approve(address(router), FUND_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(router), FUND_SFT_ID_2);
        router.stake(FUND_SFT, FUND_SFT_ID_1, sft1Balance);
        router.stake(FUND_SFT, FUND_SFT_ID_2, sft2Balance);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 routerHoldingSftId = router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, sft1Balance + sft2Balance);
        assertEq(routerHoldingSftId, 0);
        assertEq(swtHoldingValueSftId, FUND_SFT_ID_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), address(swt));
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_2), address(swt));
        assertEq(IERC3525(FUND_SFT).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1), sft1Balance + sft2Balance);
        assertEq(IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2), 0);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), sft1Balance + sft2Balance);
        vm.stopPrank();
    }

    function test_NonFirstStakeWithPartialValue() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        uint256 stakeValue1 = sft1Balance / 4;
        uint256 stakeValue2 = sft1Balance / 2;

        IERC3525(FUND_SFT).approve(FUND_SFT_ID_1, address(router), stakeValue1 + stakeValue2);
        router.stake(FUND_SFT, FUND_SFT_ID_1, stakeValue1);
        router.stake(FUND_SFT, FUND_SFT_ID_1, stakeValue2);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 routerHoldingSftId = router.holdingSftIds(FUND_SFT, GMXUSDC_SLOT);
        uint256 swtHoldingValueSftId = swt.holdingValueSftId();

        assertEq(swtBalanceAfter - swtBalanceBefore, stakeValue1 + stakeValue2);
        assertEq(IERC3525(FUND_SFT).ownerOf(FUND_SFT_ID_1), FUND_SFT_HOLDER_1);
        assertEq(IERC3525(FUND_SFT).ownerOf(routerHoldingSftId), address(router));
        assertEq(IERC3525(FUND_SFT).ownerOf(swtHoldingValueSftId), address(swt));
        assertEq(IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1), sft1Balance - stakeValue1 - stakeValue2);
        assertEq(IERC3525(FUND_SFT).balanceOf(routerHoldingSftId), 0);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), stakeValue1 + stakeValue2);
        vm.stopPrank();
    }

    function test_UnstakeWhenGivenSftId() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(router), FUND_SFT_ID_1);
        router.stake(FUND_SFT, FUND_SFT_ID_1, sft1Balance);

        uint256 swtHoldingValueSftId = swt.holdingValueSftId();
        uint256 swtHoldingValueBefore = IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 sft2BalanceBefore = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2);
        uint256 unstakeAmount = swtBalanceBefore / 4;

        uint256 slot = IERC3525(FUND_SFT).slotOf(FUND_SFT_ID_2);
        _erc20Approve(address(swt), address(router), unstakeAmount);
        uint256 toSftId = router.unstake(address(swt), unstakeAmount, FUND_SFT, slot, FUND_SFT_ID_2);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);

        assertEq(toSftId, FUND_SFT_ID_2);
        assertEq(swtBalanceBefore - swtBalanceAfter, unstakeAmount);
        assertEq(IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_2), sft2BalanceBefore + unstakeAmount);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), swtHoldingValueBefore - unstakeAmount);
        vm.stopPrank();
    }

    function test_UnstakeWhenNotGivenSftId() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 sft1Balance = IERC3525(FUND_SFT).balanceOf(FUND_SFT_ID_1);
        IERC3525(FUND_SFT).approve(address(router), FUND_SFT_ID_1);
        router.stake(FUND_SFT, FUND_SFT_ID_1, sft1Balance);

        uint256 swtHoldingValueSftId = swt.holdingValueSftId();
        uint256 swtHoldingValueBefore = IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 unstakeAmount = swtBalanceBefore / 4;

        uint256 slot = IERC3525(FUND_SFT).slotOf(FUND_SFT_ID_1);
        _erc20Approve(address(swt), address(router), unstakeAmount);
        uint256 toSftId = router.unstake(address(swt), unstakeAmount, FUND_SFT, slot, 0);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);

        assertEq(swtBalanceBefore - swtBalanceAfter, unstakeAmount);
        assertEq(IERC3525(FUND_SFT).balanceOf(toSftId), unstakeAmount);
        assertEq(IERC3525(FUND_SFT).balanceOf(swtHoldingValueSftId), swtHoldingValueBefore - unstakeAmount);
        vm.stopPrank();
    }

    function test_CreateSubscription() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 currencyBalanceBefore = _getErc20Balance(USDC_ADDRESS, FUND_SFT_HOLDER_1);
        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 subscribeCurrencyAmount = 100e6;

        ERC20(USDC_ADDRESS).approve(address(router), subscribeCurrencyAmount);
        _erc20Approve(USDC_ADDRESS, address(router), subscribeCurrencyAmount);
        router.createSubscription(GMXUSDC_POOL_ID, subscribeCurrencyAmount);
        uint256 currencyBalanceAfter = _getErc20Balance(USDC_ADDRESS, FUND_SFT_HOLDER_1);
        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);

        assertEq(currencyBalanceBefore - currencyBalanceAfter, subscribeCurrencyAmount);
        uint256 nav = _getSubscribeNav(GMXUSDC_POOL_ID, block.timestamp);
        uint256 dueSwtAmount = subscribeCurrencyAmount * (10 ** _getErc20Decimals(address(swt))) / nav;
        assertEq(swtBalanceAfter - swtBalanceBefore, dueSwtAmount);
        vm.stopPrank();
    }

    function test_CreateRedemption() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 subscribeCurrencyAmount = 100e6;
        _erc20Approve(USDC_ADDRESS, address(router), subscribeCurrencyAmount);
        router.createSubscription(GMXUSDC_POOL_ID, subscribeCurrencyAmount);

        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        uint256 redeemAmount = 20 ether;
        _erc20Approve(address(swt), address(router), redeemAmount);
        router.createRedemption(GMXUSDC_POOL_ID, redeemAmount);

        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        assertEq(swtBalanceBefore - swtBalanceAfter, redeemAmount);

        uint256 redemptionId = _getLastSftIdOwned(REDEMPTION_SFT_ADDRESS, FUND_SFT_HOLDER_1);
        uint256 redemptionBalance = _getSftBalance(REDEMPTION_SFT_ADDRESS, redemptionId);
        assertEq(redemptionBalance, redeemAmount);
        vm.stopPrank();
    }

    function test_CancelRedemption() public {
        vm.startPrank(FUND_SFT_HOLDER_1);
        uint256 subscribeCurrencyAmount = 100e6;
        _erc20Approve(USDC_ADDRESS, address(router), subscribeCurrencyAmount);
        router.createSubscription(GMXUSDC_POOL_ID, subscribeCurrencyAmount);

        uint256 redeemAmount = 20 ether;
        _erc20Approve(address(swt), address(router), redeemAmount);
        router.createRedemption(GMXUSDC_POOL_ID, redeemAmount);
        uint256 redemptionId = _getLastSftIdOwned(REDEMPTION_SFT_ADDRESS, FUND_SFT_HOLDER_1);

        uint256 swtBalanceBefore = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        _approveSftId(REDEMPTION_SFT_ADDRESS, address(router), redemptionId);
        router.cancelRedemption(GMXUSDC_POOL_ID, redemptionId);

        uint256 swtBalanceAfter = _getErc20Balance(address(swt), FUND_SFT_HOLDER_1);
        assertEq(swtBalanceAfter - swtBalanceBefore, redeemAmount);

        vm.expectRevert("ERC3525: invalid token ID");
        IERC3525(REDEMPTION_SFT_ADDRESS).ownerOf(redemptionId);
        vm.stopPrank();
    }


    /** Internal functions */
    function _deploySftWrappedToken() internal {
        vm.startPrank(ADMIN);
        SftWrappedToken swtImpl = new SftWrappedToken();
        factory.setImplementation(PRODUCT_TYPE_YIELDS, address(swtImpl));
        factory.deployBeacon(PRODUCT_TYPE_YIELDS);
        swt = SftWrappedToken(
            factory.deployProductProxy(PRODUCT_TYPE_YIELDS, PRODUCT_NAME_GMXUSDC, TOKEN_NAME_GMXUSDC, TOKEN_SYMBOL_GMXUSDC, FUND_SFT, GMXUSDC_SLOT, NAV_ORACLE_ADDRESS)
        );
        vm.stopPrank();
    }

    function _deploySolvBTCMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        bytes32 implSalt = keccak256(abi.encodePacked(ADMIN));
        SolvBTCMultiAssetPool impl = new SolvBTCMultiAssetPool{salt: implSalt}();
        bytes32 proxySalt = keccak256(abi.encodePacked(impl));
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{salt: proxySalt}(
            address(impl), address(proxyAdmin), abi.encodeWithSignature("initialize(address)", ADMIN)
        );
        solvBTCMultiAssetPool = SolvBTCMultiAssetPool(address(proxy));
        vm.stopPrank();
    }

    function _upgradeSolvBTC() internal {
        vm.startPrank(ADMIN);
        SolvBTC solvBTCImpl = new SolvBTC();
        factory.setImplementation(PRODUCT_TYPE_SOLVBTC, address(solvBTCImpl));
        factory.upgradeBeacon(PRODUCT_TYPE_SOLVBTC);
        vm.stopPrank();
    }

    function _setupSolvBTC() internal {
        vm.startPrank(ADMIN);
        solvBTC.initializeV2(address(solvBTCMultiAssetPool));
        solvBTC.grantRole(solvBTC.SOLVBTC_MINTER_ROLE(), address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }

    function _setupMultiAssetPool() internal {
        vm.startPrank(ADMIN);
        solvBTCMultiAssetPool.addSftSlotOnlyAdmin(SOLVBTC_SFT, SOLVBTC_SLOT, address(solvBTC), SOLVBTC_HOLDING_VALUE_SFT_ID);
        vm.stopPrank();
    }

    function _upgradeRouter() internal {
        vm.startPrank(ADMIN);
        SftWrapRouter newRouterImpl = new SftWrapRouter();
        (bool success, ) = address(proxyAdmin).call(abi.encodeWithSignature("upgrade(address,address)", address(router), address(newRouterImpl)));
        require(success, "upgrade router failed");
        router.setSolvBTCMultiAssetPool(address(solvBTCMultiAssetPool));
        vm.stopPrank();
    }


    function _erc20Approve(address _erc20, address _spender, uint256 _allowance) internal {
        (bool success, ) = _erc20.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _allowance));
        require(success, "erc20 approve failed");
    }

    function _getErc20Decimals(address _erc20) internal returns (uint8 decimals) {
        (bool success, bytes memory result) = _erc20.call(abi.encodeWithSignature("decimals()"));
        require(success, "get erc20 decimals failed");
        (decimals) = abi.decode(result, (uint8));
    }

    function _getErc20Balance(address _erc20, address _owner) internal returns (uint256 balance) {
        (bool success, bytes memory result) = _erc20.call(abi.encodeWithSignature("balanceOf(address)", _owner));
        require(success, "get erc20 balance failed");
        (balance) = abi.decode(result, (uint256));
    }


    function _getSubscribeNav(bytes32 _poolId, uint256 _timestamp) internal returns (uint256 nav) {
        (bool success, bytes memory result) = NAV_ORACLE_ADDRESS.call(abi.encodeWithSignature("getSubscribeNav(bytes32,uint256)", _poolId, _timestamp));
        require(success, "get nav failed");
        (nav, ) = abi.decode(result, (uint256, uint256));
    }


    function _approveSftId(address _sft, address _spender, uint256 _sftId) internal {
        (bool success, ) = _sft.call(abi.encodeWithSignature("approve(address,uint256)", _spender, _sftId));
        require(success, "approve sft id failed");
    }

    function _approveSftValue(address _sft, address _spender, uint256 _sftId, uint256 _allowance) internal {
        (bool success, ) = _sft.call(abi.encodeWithSignature("approve(uint256,address,uint256)", _sftId, _spender, _allowance));
        require(success, "approve sft id failed");
    }

    function _safeTransferSftId(address _from, address _to, uint256 _sftId) internal {
        (bool success, ) = FUND_SFT.call(abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", _from, _to, _sftId));
        require(success, "safe transfer sft id failed");
    }

    function _transferSftValueToId(uint256 _fromSftId, uint256 _toSftId, uint256 _transferValue) internal {
        (bool success, ) = FUND_SFT.call(abi.encodeWithSignature("transferFrom(uint256,uint256,uint256)", _fromSftId, _toSftId, _transferValue));
        require(success, "safe transfer sft value to id failed");
    }

    function _transferSftValueToAddress(uint256 _fromSftId, address _to, uint256 _transferValue) internal {
        (bool success, ) = FUND_SFT.call(abi.encodeWithSignature("transferFrom(uint256,address,uint256)", _fromSftId, _to, _transferValue));
        require(success, "safe transfer sft value to address failed");
    }

    function _getSftBalance(address _sft, uint256 _sftId) internal returns (uint256 balance) {
        (bool success, bytes memory result) = _sft.call(abi.encodeWithSignature("balanceOf(uint256)", _sftId));
        require(success, "get sft balance failed");
        (balance) = abi.decode(result, (uint256));
    }

    function _getSftOwner(address _sft, uint256 _sftId) internal returns (address owner) {
        (bool success, bytes memory result) = _sft.call(abi.encodeWithSignature("ownerOf(uint256)", _sftId));
        require(success, "get sft owner failed");
        (owner) = abi.decode(result, (address));
    }

    function _getLastSftIdOwned(address _sft, address _owner) internal returns (uint256 sftId) {
        (, bytes memory result1) = _sft.call(abi.encodeWithSignature("balanceOf(address)", _owner));
        (uint256 balance) = abi.decode(result1, (uint256));
        (bool success, bytes memory result) = _sft.call(abi.encodeWithSignature("tokenOfOwnerByIndex(address,uint256)", _owner, balance - 1));
        require(success, "get last sft if owned failed");
        (sftId) = abi.decode(result, (uint256));
    }

}