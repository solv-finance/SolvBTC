const assert = require('assert');
const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const SolvBTCYieldTokenOracleFactory = await ethers.getContractFactory('SolvBTCYieldTokenOracleForSFT', deployer);
  const solvBTCYieldTokenOracleAddress = (await deployments.get('SolvBTCYieldTokenOracleForSFTProxy')).address;
  const solvBTCYieldTokenOracle = SolvBTCYieldTokenOracleFactory.attach(solvBTCYieldTokenOracleAddress);

  const productType = 'SolvBTC Yield Token';
  const productInfos = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  for (let productName in productInfos[network.name]) {
    let info = productInfos[network.name][productName];
    let tokenAddress = await solvBTCYieldTokenFactory.getProxy(productType, productName);
    assert(tokenAddress == info.erc20, `${network.name} ${productName} tokenAddress not matched`);

    let sftInfoInOracle = await solvBTCYieldTokenOracle.sftOracles(info.erc20);
    if (sftInfoInOracle.sft == ethers.constants.AddressZero) {
      let configOracleTx = await solvBTCYieldTokenOracle.setSFTOracle(info.erc20, info.sft, info.slot, info.poolId, info.navOracle);
      console.log(`* INFO: config SolvBYCYieldTokenOracle for ${productName} at ${configOracleTx.hash}`);
      await txWait(configOracleTx);
    } else {
      console.log(`* INFO: SolvBYCYieldTokenOracle for ${productName} already set`);
    }
  }
};

module.exports.tags = ['SetSolvBTCYTOracle']
