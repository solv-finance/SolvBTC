const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCMultiAssetPoolAddress = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;
  const solvBTCMultiAssetPool = SolvBTCMultiAssetPoolFactory.attach(solvBTCMultiAssetPoolAddress);

  const allowCallers = [
    (await deployments.get('SolvBTCRouterProxy')).address,
    (await deployments.get('SolvBTCRouterV2Proxy')).address,
  ];

  const tx = await solvBTCMultiAssetPool.setCallerAllowedOnlyAdmin(allowCallers, true);
  console.log(`* SolvBTCMultiAssetPool: SetCallerAllowed at tx ${tx.hash}`);
  await txWait(tx);

};

module.exports.tags = ['SolvBTCMultiAssetPool_SetCaller']
