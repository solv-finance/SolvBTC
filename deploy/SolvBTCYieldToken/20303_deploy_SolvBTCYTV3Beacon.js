const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryV3Factory = await ethers.getContractFactory('SolvBTCFactoryV3', deployer);
  const solvBTCYieldTokenFactoryV3Address = (await deployments.get('SolvBTCYieldTokenFactoryV3')).address;
  const solvBTCYieldTokenFactoryV3 = SolvBTCYieldTokenFactoryV3Factory.attach(solvBTCYieldTokenFactoryV3Address);

  const productType = 'SolvBTC Yield Token';
  const version = '_v3.0';
  const implementation = (await deployments.get('SolvBTCYieldToken' + version)).address;

  let beaconAddress = await solvBTCYieldTokenFactoryV3.getBeacon(productType);
  let implAddress = await solvBTCYieldTokenFactoryV3.getImplementation(productType);
  if (beaconAddress == ethers.constants.AddressZero) {
    const deployBeaconTx = await solvBTCYieldTokenFactoryV3.setImplementation(productType, implementation);
    console.log(`* INFO: Deploy SolvBTCYieldTokenV3 beacon at ${deployBeaconTx.hash}`);
    await txWait(deployBeaconTx);

    beaconAddress = await solvBTCYieldTokenFactoryV3.getBeacon(productType);
    implAddress = await solvBTCYieldTokenFactoryV3.getImplementation(productType);
    console.log(`* INFO: SolvBTCYieldTokenV3 beacon deployed at ${colors.yellow(beaconAddress)} pointing to implementation ${implAddress}`);
  } else {
    console.log(`* INFO: SolvBTCYieldTokenV3 beacon already deployed at ${colors.yellow(beaconAddress)} pointing to implementation ${implAddress}`);
  }
};

module.exports.tags = ['SolvBTCYTV3Beacon']
