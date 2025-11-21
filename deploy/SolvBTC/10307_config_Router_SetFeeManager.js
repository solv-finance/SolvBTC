const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCRouterFactory = await ethers.getContractFactory('SolvBTCRouter', deployer);
  const solvBTCRouterAddress = (await deployments.get('SolvBTCRouterProxy')).address;
  const solvBTCRouter = SolvBTCRouterFactory.attach(solvBTCRouterAddress);

  const feeManagerAddress = (await deployments.get('FeeManagerProxy')).address;

  const currentFeeManager = await solvBTCRouter.feeManager();
  if (currentFeeManager == feeManagerAddress) {
    console.log(`* SolvBTCRouter: FeeManager is already ${currentFeeManager}`);
  } else {
    const tx = await solvBTCRouter.setFeeManager(feeManagerAddress);
    console.log(`* SolvBTCRouter: SetFeeManager for ${feeManagerAddress} at tx ${tx.hash}`);
    await txWait(tx);
  }

};

module.exports.tags = ['SolvBTCRouter_SetFeeManager']
