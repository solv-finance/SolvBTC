const assert = require('assert');
const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCYieldTokenFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const productType = 'SolvBTC Yield Token';
  const implementation = (await deployments.get('SolvBTCYieldToken_v2.0')).address;

  const upgradeBeaconTx = await solvBTCYieldTokenFactory.setImplementation(productType, implementation);
  console.log(`* INFO: Upgrade SolvBTC at ${upgradeBeaconTx.hash}`);
  await txWait(upgradeBeaconTx);

  const solvBTCYTMultiAssetPool = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenOracle = (await deployments.get('SolvBTCYieldTokenOracleForSFTProxy')).address;

  const solvBTCYieldTokenInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const SolvBTCYieldTokenFactory_ = await ethers.getContractFactory('SolvBTCYieldToken', deployer);
  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let tokenAddress = await solvBTCYieldTokenFactory.getProxy(productType, productName);
    assert(tokenAddress == solvBTCYieldTokenInfos[network.name][productName].erc20, `${productName} token address not matched`);
    let token = SolvBTCYieldTokenFactory_.attach(tokenAddress);

    let initializeV2Tx = await token.initializeV2(solvBTCYTMultiAssetPool);
    console.log(`* INFO: ${tokenInfo[0]} initializeV2 at ${initializeV2Tx.hash}`);
    await txWait(initializeV2Tx);

    let setOracleTx = await token.setOracle(solvBTCYieldTokenOracle);
    console.log(`* INFO: ${tokenInfo[0]} setOracle at ${setOracleTx.hash}`);
    await txWait(setOracleTx);
  }

};

module.exports.tags = ['UpgradeSolvBTCYT']
