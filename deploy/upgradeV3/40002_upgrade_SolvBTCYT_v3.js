const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const deployer = await hre.zksyncEthers.getWallet();

  const SolvBTCFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const productType = 'SolvBTC Yield Token';
  const implementation = (await deployments.get('SolvBTCYieldToken_v3.1')).address;

  const implInSolvBTCFactory = await solvBTCFactory.getImplementation(productType);
  if (implInSolvBTCFactory != implementation) {
    const upgradeBeaconTx = await solvBTCFactory.setImplementation(productType, implementation);
    console.log(`* INFO: Upgrade SolvBTCYieldToken beacon at ${upgradeBeaconTx.hash}`);
    await txWait(upgradeBeaconTx);
  } else {
    console.log(`* INFO: SolvBTCYieldToken beacon already upgraded to latest implementation ${implementation}`);
  }
};

module.exports.tags = ['UpgradeSolvBTCYT_V3']
