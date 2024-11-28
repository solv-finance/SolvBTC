const colors = require('colors');
const { getSigner, txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await getSigner(deployer);

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', signer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const productType = 'SolvBTC Yield Token';
  const version = '_v2.0';
  const implementation = (await deployments.get('SolvBTCYieldToken' + version)).address;

  let beaconAddress = await solvBTCYieldTokenFactory.getBeacon(productType);
  let implAddress = await solvBTCYieldTokenFactory.getImplementation(productType);
  if (beaconAddress == ethers.ZeroAddress) {
    const deployBeaconTx = await solvBTCYieldTokenFactory.setImplementation(productType, implementation);
    console.log(`* INFO: Deploy SolvBTCYieldToken beacon at ${deployBeaconTx.hash}`);
    await txWait(deployBeaconTx);

    beaconAddress = await solvBTCYieldTokenFactory.getBeacon(productType);
    implAddress = await solvBTCYieldTokenFactory.getImplementation(productType);
    console.log(`* INFO: SolvBTCYieldToken beacon deployed at ${colors.yellow(beaconAddress)} pointing to implementation ${implAddress}`);
  } else {
    console.log(`* INFO: SolvBTCYieldToken beacon already deployed at ${colors.yellow(beaconAddress)} pointing to implementation ${implAddress}`);
  }
};

module.exports.tags = ['SolvBTCYTBeacon']
