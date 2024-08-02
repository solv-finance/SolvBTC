const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCYieldTokenFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const productType = 'SolvBTC Yield Token';
  const version = '_v2.0';
  const implementation = (await deployments.get('SolvBTCYieldToken' + version)).address;

  const deployBeaconTx = await solvBTCYieldTokenFactory.setImplementation(productType, implementation);
  console.log(`* INFO: Deploy SolvBTCYieldToken beacon at ${deployBeaconTx.hash}`);
  await txWait(deployBeaconTx);
};

module.exports.tags = ['SolvBTCYTBeacon']
