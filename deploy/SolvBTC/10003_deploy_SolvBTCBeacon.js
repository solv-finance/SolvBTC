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

  let beaconAddress = await solvBTCFactory.getBeacon(productType);
  let implAddress = await solvBTCFactory.getImplementation(productType);
  if (beaconAddress == ethers.constants.AddressZero) {
    const deployBeaconTx = await solvBTCFactory.setImplementation(productType, implementation);
    console.log(`* INFO: Deploy SolvBTC beacon at ${deployBeaconTx.hash}`);
    await txWait(deployBeaconTx);

    beaconAddress = await solvBTCFactory.getBeacon(productType);
    implAddress = await solvBTCFactory.getImplementation(productType);
    console.log(`* INFO: SolvBTC beacon deployed at ${beaconAddress} pointing to implementation ${implAddress}`);
  } else {
    console.log(`* INFO: SolvBTC beacon already deployed at ${beaconAddress} pointing to implementation ${implAddress}`);
  }

};

module.exports.tags = ['SolvBTCBeacon']
