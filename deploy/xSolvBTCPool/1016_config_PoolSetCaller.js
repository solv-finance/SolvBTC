const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const XSolvBTCPoolFactory = await ethers.getContractFactory('XSolvBTCPool', deployer);
  const xSolvBTCPoolAddress = (await deployments.get('XSolvBTCPoolProxy')).address;
  const xSolvBTCPool = XSolvBTCPoolFactory.attach(xSolvBTCPoolAddress);

  const allowCallers = [
    (await deployments.get('SolvBTCRouterV2Proxy')).address,
  ];

  const tx = await xSolvBTCPool.setCallerAllowedOnlyAdmin(allowCallers, true);
  console.log(`* xSolvBTCPool: SetCallerAllowed at tx ${tx.hash}`);
  await txWait(tx);

};

module.exports.tags = ['xSolvBTCPool_SetCaller']
