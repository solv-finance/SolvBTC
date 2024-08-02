const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const openFundMarketAddress = require('./10999_export_SolvBTCInfos').OpenFundMarketAddresses[network.name];
  const solvBTCFactoryAddress = require('./10999_export_SolvBTCInfos').SolvBTCFactoryAddresses[network.name];
  const solvBTCMultiAssetPoolAddress = require('./10999_export_SolvBTCInfos').SolvBTCMultiAssetPoolAddresses[network.name];
  const solvBTCBeaconAddress = require('./10999_export_SolvBTCInfos').SolvBTCBeaconAddresses[network.name];
  const solvBTCImplAddress = (await deployments.get('SolvBTC_v2.0')).address;
  const solvBTCInfos = require('./10999_export_SolvBTCInfos').SolvBTCInfos[network.name];
  const productType = 'Solv BTC';
  const productName = 'Solv BTC';

  const SolvBTCRouterFactory = await ethers.getContractFactory('SolvBTCRouter', deployer);
  const solvBTCRouterAddress = (await deployments.get('SolvBTCRouterProxy')).address;
  const solvBTCRouter = SolvBTCRouterFactory.attach(solvBTCRouterAddress);
  
  const SolvBTCFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const SolvBTCMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCMultiAssetPool = SolvBTCMultiAssetPoolFactory.attach(solvBTCMultiAssetPoolAddress);

  // verify router status
  const marketInRouter = await solvBTCRouter.openFundMarket();
  const poolInRouter = await solvBTCRouter.solvBTCMultiAssetPool();
  assert(marketInRouter, openFundMarketAddress, 'Router: market address not matched');
  assert(poolInRouter, solvBTCMultiAssetPoolAddress, 'Router: pool address not matched');

  // verify factory status
  const beaconInFactory = await solvBTCFactory.getBeacon(productType);
  const implInFactory = await solvBTCFactory.getImplementation(productType);
  const proxyInFactory = await solvBTCFactory.getProxy(productType, productName);
  assert(beaconInFactory == solvBTCBeaconAddress, 'Factory: beacon address not matched');
  assert(implInFactory == solvBTCImplAddress, 'Factory: implememtation address not matched');
  assert(proxyInFactory == solvBTCInfos.erc20, 'Factory: proxy address not matched');

  // verify pool status
  const isDepositAllowed = await solvBTCMultiAssetPool.isSftSlotDepositAllowed(solvBTCInfos.sft, solvBTCInfos.slot);
  const isWithdrawAllowed = await solvBTCMultiAssetPool.isSftSlotWithdrawAllowed(solvBTCInfos.sft, solvBTCInfos.slot);
  const erc20 = await solvBTCMultiAssetPool.getERC20(solvBTCInfos.sft, solvBTCInfos.slot);
  const holdingValueSftId = await solvBTCMultiAssetPool.getHoldingValueSftId(solvBTCInfos.sft, solvBTCInfos.slot);
  assert(isDepositAllowed, 'Pool: SolvBTC deposit not allowed');
  assert(isWithdrawAllowed, 'Pool: SolvBTC withdraw not allowed');
  assert(erc20 == solvBTCInfos.erc20, 'Pool: erc20 address not matched');
  assert(holdingValueSftId == solvBTCInfos.holdingValueSftId, 'Pool: holdingValueSftId not matched');

  // verify SolvBTC status
  const SolvBTCFactory_ = await ethers.getContractFactory('SolvBTC', deployer);
  const solvBTC = SolvBTCFactory_.attach(solvBTCInfos.erc20);
  const poolInErc20 = await solvBTC.solvBTCMultiAssetPool();
  const minterRole = await solvBTC.SOLVBTC_MINTER_ROLE();
  const poolHasMinterRole = await solvBTC.hasRole(minterRole, poolInErc20);
  assert(poolInErc20 == solvBTCMultiAssetPoolAddress, 'SolvBTC: pool address not matched');
  assert(poolHasMinterRole, 'SolvBTC: pool not granted minter role')

  const wrappedSftAddressInErc20 = await solvBTC.wrappedSftAddress();
  const wrappedSftSlotInErc20 = await solvBTC.wrappedSftSlot();
  const navOracleInErc20 = await solvBTC.navOracle();
  const holdingValueSftIdInErc20 = await solvBTC.holdingValueSftId();
  assert(wrappedSftAddressInErc20 == ethers.constants.AddressZero, 'SolvBTC: wrappedSftAddress not deleted');
  assert(wrappedSftSlotInErc20 == 0, 'SolvBTC: wrappedSftSlot not deleted');
  assert(navOracleInErc20 == ethers.constants.AddressZero, 'SolvBTC: navOracle not deleted');
  assert(holdingValueSftIdInErc20 == 0, 'SolvBTC: holdingValueSftId not deleted');
};

module.exports.tags = ['VerifySolvBTCStatus']
