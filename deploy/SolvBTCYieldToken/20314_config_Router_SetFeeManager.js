const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYTRouterFactory = await ethers.getContractFactory("SolvBTCRouter", deployer);
  const solvBTCYTRouterAddress = (await deployments.get('SolvBTCYieldTokenRouterProxy')).address;
  const solvBTCYTRouter = SolvBTCYTRouterFactory.attach(solvBTCYTRouterAddress);

  const feeManagerAddress = (await deployments.get('FeeManagerProxy')).address;

  const currentFeeManager = await solvBTCYTRouter.feeManager();
  if (currentFeeManager == feeManagerAddress) {
    console.log(`* SolvBTCYieldTokenRouter: FeeManager is already ${currentFeeManager}`);
  } else {
    const tx = await solvBTCYTRouter.setFeeManager(feeManagerAddress);
    console.log(`* SolvBTCYieldTokenRouter: SetFeeManager for ${feeManagerAddress} at tx ${tx.hash}`);
    await txWait(tx);
  }

};

module.exports.tags = ['SolvBTCYieldTokenRouter_SetFeeManager']
