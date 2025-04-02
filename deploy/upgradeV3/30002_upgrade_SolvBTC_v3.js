const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const deployer = await hre.zksyncEthers.getWallet();

  const SolvBTCFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCFactoryAddress = (await deployments.get('SolvBTCFactory')).address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const productType = 'Solv BTC';
  const implementation = (await deployments.get('SolvBTC_v3.1')).address;

  const implInSolvBTCFactory = await solvBTCFactory.getImplementation(productType);
  console.log(`* INFO: Current implementation of ${productType} is ${implInSolvBTCFactory}`);
  if (implInSolvBTCFactory != implementation) {
    const upgradeBeaconTx = await solvBTCFactory.setImplementation(productType, implementation);
    console.log(`* INFO: Upgrade SolvBTC at ${upgradeBeaconTx.hash}`);
    await txWait(upgradeBeaconTx);
  } else {
    console.log(`* INFO: SolvBTC already upgraded to latest implementation ${implementation}`);
  }
};

module.exports.tags = ['UpgradeSolvBTC_V3']
