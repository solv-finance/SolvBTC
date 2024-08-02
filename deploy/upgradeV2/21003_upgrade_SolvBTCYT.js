const assert = require('assert');
const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const productType = 'SolvBTC Yield Token';
  const implementation = (await deployments.get('SolvBTCYieldToken_v2.0')).address;

  const beaconInFactory = await solvBTCYieldTokenFactory.getImplementation(productType);
  if (beaconInFactory != implementation) {
    const upgradeBeaconTx = await solvBTCYieldTokenFactory.setImplementation(productType, implementation);
    console.log(`* INFO: Upgrade SolvBTCYieldToken at ${upgradeBeaconTx.hash}`);
    await txWait(upgradeBeaconTx);
  } else {
    console.log(`* INFO: SolvBTCYieldToken already upgraded to latest implementation ${implementation}`);
  }

  const solvBTCYTMultiAssetPool = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenOracle = (await deployments.get('SolvBTCYieldTokenOracleForSFTProxy')).address;

  const solvBTCYieldTokenInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const SolvBTCYieldTokenFactory_ = await ethers.getContractFactory('SolvBTCYieldToken', deployer);
  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let tokenAddress = await solvBTCYieldTokenFactory.getProxy(productType, productName);
    assert(tokenAddress == solvBTCYieldTokenInfos[network.name][productName].erc20, `${productName} token address not matched`);
    let token = SolvBTCYieldTokenFactory_.attach(tokenAddress);

    let poolInSolvBTCYieldToken = await token.solvBTCMultiAssetPool();
    if (poolInSolvBTCYieldToken == ethers.constants.AddressZero) {
      let initializeV2Tx = await token.initializeV2(solvBTCYTMultiAssetPool);
      console.log(`* INFO: ${productName} initializeV2 at ${initializeV2Tx.hash}`);
      await txWait(initializeV2Tx);
    } else {
      console.log(`* INFO: ${productName} initializeV2 already executed`);
    }

    let oracleInSolvBTCYieldToken = await token.getOracle();
    if (oracleInSolvBTCYieldToken == ethers.constants.AddressZero) {
      let setOracleTx = await token.setOracle(solvBTCYieldTokenOracle);
      console.log(`* INFO: ${productName} setOracle at ${setOracleTx.hash}`);
      await txWait(setOracleTx);
    } else {
      console.log(`* INFO: ${productName} oracle already set`);
    }
  }
};

module.exports.tags = ['UpgradeSolvBTCYT']
