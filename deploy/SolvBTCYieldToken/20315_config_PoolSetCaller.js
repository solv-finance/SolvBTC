const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCYieldTokenMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenMultiAssetPool = SolvBTCYieldTokenMultiAssetPoolFactory.attach(solvBTCYieldTokenMultiAssetPoolAddress);

  const allowCallers = [
    (await deployments.get('SolvBTCYieldTokenRouterProxy')).address,
    (await deployments.get('SolvBTCRouterV2Proxy')).address,
  ];

  const tx = await solvBTCYieldTokenMultiAssetPool.setCallerAllowedOnlyAdmin(allowCallers, true);
  console.log(`* SolvBTCYieldTokenMultiAssetPool: SetCallerAllowed at tx ${tx.hash}`);
  await txWait(tx);

};

module.exports.tags = ['SolvBTCYTMultiAssetPool_SetCaller']
