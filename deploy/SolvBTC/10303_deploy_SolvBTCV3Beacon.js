const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactoryV3Factory = await ethers.getContractFactory('SolvBTCFactoryV3', deployer);
  const solvBTCFactoryV3Address = (await deployments.get('SolvBTCFactoryV3')).address;
  const solvBTCFactoryV3 = SolvBTCFactoryV3Factory.attach(solvBTCFactoryV3Address);

  const productType = 'Solv BTC';
  const version = '_v3.0';
  const implementation = (await deployments.get('SolvBTC' + version)).address;

  let beaconAddress = await solvBTCFactoryV3.getBeacon(productType);
  let implAddress = await solvBTCFactoryV3.getImplementation(productType);
  if (beaconAddress == ethers.constants.AddressZero) {
    const deployBeaconTx = await solvBTCFactoryV3.setImplementation(productType, implementation);
    console.log(`* INFO: Deploy SolvBTCV3 beacon at ${deployBeaconTx.hash}`);
    await txWait(deployBeaconTx);

    beaconAddress = await solvBTCFactoryV3.getBeacon(productType);
    implAddress = await solvBTCFactoryV3.getImplementation(productType);
    console.log(`* INFO: SolvBTCV3 beacon deployed at ${colors.yellow(beaconAddress)} pointing to implementation ${implAddress}`);
  } else {
    console.log(`* INFO: SolvBTCV3 beacon already deployed at ${colors.yellow(beaconAddress)} pointing to implementation ${implAddress}`);
  }

};

module.exports.tags = ['SolvBTCV3Beacon']
