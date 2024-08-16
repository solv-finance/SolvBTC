const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const openFundMarketAddress = require('../SolvBTC/10999_export_SolvBTCInfos').OpenFundMarketAddresses[network.name];
  const solvBTCYieldTokenFactoryAddress = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenFactoryAddresses[network.name];
  const solvBTCYieldTokenMultiAssetPoolAddress = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenMultiAssetPoolAddresses[network.name];
  const solvBTCYieldTokenBeaconAddress = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenBeaconAddresses[network.name];
  const solvBTCYieldTokenImplAddress = (await deployments.get('SolvBTCYieldToken_v2.0')).address;
  const solvBTCYieldTokenInfos = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos[network.name];
  const productType = 'SolvBTC Yield Token';

  const SolvBTCYieldTokenRouterFactory = await ethers.getContractFactory('SolvBTCRouter', deployer);
  const solvBTCYieldTokenRouterAddress = (await deployments.get('SolvBTCYieldTokenRouterProxy')).address;
  const solvBTCYieldTokenRouter = SolvBTCYieldTokenRouterFactory.attach(solvBTCYieldTokenRouterAddress);
  
  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const SolvBTCYieldTokenMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCYieldTokenMultiAssetPool = SolvBTCYieldTokenMultiAssetPoolFactory.attach(solvBTCYieldTokenMultiAssetPoolAddress);

  const SolvBTCYieldTokenOracleFactory = await ethers.getContractFactory('SolvBTCYieldTokenOracleForSFT', deployer);
  const solvBTCYieldTokenOracleAddress = (await deployments.get('SolvBTCYieldTokenOracleForSFTProxy')).address;
  const solvBTCYieldTokenOracle = SolvBTCYieldTokenOracleFactory.attach(solvBTCYieldTokenOracleAddress);

  // verify router status
  const marketInRouter = await solvBTCYieldTokenRouter.openFundMarket();
  const poolInRouter = await solvBTCYieldTokenRouter.solvBTCMultiAssetPool();
  assert(marketInRouter, openFundMarketAddress, 'Router: market address not matched');
  assert(poolInRouter, solvBTCYieldTokenMultiAssetPoolAddress, 'Router: pool address not matched');

  // verify factory status for beacon/implementation
  const beaconInFactory = await solvBTCYieldTokenFactory.getBeacon(productType);
  const implInFactory = await solvBTCYieldTokenFactory.getImplementation(productType);
  assert(beaconInFactory == solvBTCYieldTokenBeaconAddress, 'Factory: beacon address not matched');
  assert(implInFactory == solvBTCYieldTokenImplAddress, 'Factory: implememtation address not matched');

  for (let productName in solvBTCYieldTokenInfos) {
    const tokenInfo = solvBTCYieldTokenInfos[productName];

    // verify factory status for proxy
    const proxyInFactory = await solvBTCYieldTokenFactory.getProxy(productType, productName);
    assert(proxyInFactory == tokenInfo.erc20, `Factory: ${productName} proxy address not matched`);

    // verify oracle status
    const sftInfoInOracle = await solvBTCYieldTokenOracle.sftOracles(tokenInfo.erc20);
    assert(sftInfoInOracle.sft.toUpperCase() == tokenInfo.sft.toUpperCase(), `Oracle: ${productName} sft address not matched`);
    assert(sftInfoInOracle.sftSlot == tokenInfo.slot, `Oracle: ${productName} sft slot not matched`);
    assert(sftInfoInOracle.poolId == tokenInfo.poolId, `Oracle: ${productName} poolId address not matched`);

    // verify pool status
    const isDepositAllowed = await solvBTCYieldTokenMultiAssetPool.isSftSlotDepositAllowed(tokenInfo.sft, tokenInfo.slot);
    const isWithdrawAllowed = await solvBTCYieldTokenMultiAssetPool.isSftSlotWithdrawAllowed(tokenInfo.sft, tokenInfo.slot);
    const erc20 = await solvBTCYieldTokenMultiAssetPool.getERC20(tokenInfo.sft, tokenInfo.slot);
    const holdingValueSftId = await solvBTCYieldTokenMultiAssetPool.getHoldingValueSftId(tokenInfo.sft, tokenInfo.slot);
    assert(isDepositAllowed, `Pool: ${productName} deposit not allowed`);
    assert(isWithdrawAllowed, `Pool: ${productName} withdraw not allowed`);
    assert(erc20 == tokenInfo.erc20, `Pool: ${productName} erc20 address not matched`);
    assert(holdingValueSftId == tokenInfo.holdingValueSftId, `Pool: ${productName} holdingValueSftId not matched`);

    // verify SolvBTCYieldToken status
    const SolvBTCYieldTokenFactory_ = await ethers.getContractFactory('SolvBTCYieldToken', deployer);
    const solvBTCYieldToken = SolvBTCYieldTokenFactory_.attach(tokenInfo.erc20);
    const oracleInErc20 = await solvBTCYieldToken.getOracle();
    const poolInErc20 = await solvBTCYieldToken.solvBTCMultiAssetPool();
    const minterRole = await solvBTCYieldToken.SOLVBTC_MINTER_ROLE();
    const poolHasMinterRole = await solvBTCYieldToken.hasRole(minterRole, poolInErc20);
    assert(oracleInErc20 == solvBTCYieldTokenOracleAddress, `SolvBTCYieldToken: ${productName} oracle address not matched`);
    assert(poolInErc20 == solvBTCYieldTokenMultiAssetPoolAddress, `SolvBTCYieldToken: ${productName} pool address not matched`);
    assert(poolHasMinterRole, `SolvBTCYieldToken: ${productName} pool not granted minter role`);

    const wrappedSftAddressInErc20 = await solvBTCYieldToken.wrappedSftAddress();
    const wrappedSftSlotInErc20 = await solvBTCYieldToken.wrappedSftSlot();
    const navOracleInErc20 = await solvBTCYieldToken.navOracle();
    const holdingValueSftIdInErc20 = await solvBTCYieldToken.holdingValueSftId();
    assert(wrappedSftAddressInErc20 == ethers.constants.AddressZero, `SolvBTCYieldToken: ${productName} wrappedSftAddress not deleted`);
    assert(wrappedSftSlotInErc20 == 0, `SolvBTCYieldToken: ${productName} wrappedSftSlot not deleted`);
    assert(navOracleInErc20 == ethers.constants.AddressZero, `SolvBTCYieldToken: ${productName} navOracle not deleted`);
    assert(holdingValueSftIdInErc20 == 0, `SolvBTCYieldToken: ${productName} holdingValueSftId not deleted`);
  }

};

module.exports.tags = ['VerifySolvBTCYTStatus']
