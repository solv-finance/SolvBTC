const transparentUpgrade = require('../utils/transparentUpgrade');
const gasTracker = require('../utils/gasTracker');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const gasPrice = await gasTracker.getGasPrice(network.name);

  const contractName = 'SolvBTCMultiAssetPool';
  const firstImplName = 'SolvBTCYieldTokenMultiAssetPoolImpl';
  const proxyName = 'SolvBTCYieldTokenMultiAssetPoolProxy';

  const versions = {}
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const { proxy, newImpl, newImplName } = await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
      gasPrice: gasPrice,
      log: true
    },
    {
      initializer: { 
        method: "initialize", 
        args: [] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['SolvBTCYTMultiAssetPool']
