const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCFactoryAddress = (await deployments.get('SolvBTCFactory')).address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const productType = 'Solv BTC';
  const version = '_v2.0';
  const implementation = (await deployments.get('SolvBTC' + version)).address;

  const deployBeaconTx = await solvBTCFactory.setImplementation(productType, implementation);
  console.log(`* INFO: Deploy SolvBTC beacon at ${deployBeaconTx.hash}`);
  await txWait(deployBeaconTx);
};

module.exports.tags = ['SolvBTCBeacon']
