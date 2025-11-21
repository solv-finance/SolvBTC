const { txWait } = require('./utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCRouterV2Factory = await ethers.getContractFactory("SolvBTCRouterV2", deployer);
  const solvBTCRouterV2Address = (await deployments.get('SolvBTCRouterV2Proxy')).address;
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(solvBTCRouterV2Address);

  const feeManagerAddress = (await deployments.get('FeeManagerProxy')).address;

  const currentFeeManager = await solvBTCRouterV2.feeManager();
  if (currentFeeManager == feeManagerAddress) {
    console.log(`* SolvBTCRouterV2: FeeManager is already ${currentFeeManager}`);
  } else {
    const tx = await solvBTCRouterV2.setFeeManager(feeManagerAddress);
    console.log(`* SolvBTCRouterV2: SetFeeManager for ${feeManagerAddress} at tx ${tx.hash}`);
    await txWait(tx);
  }
};

module.exports.tags = ['SolvBTCRouterV2_SetFeeManager']
