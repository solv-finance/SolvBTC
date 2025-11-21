const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const contractName = 'SolvBTCMultiAssetPool';
  const firstImplName = 'SolvBTCYieldTokenMultiAssetPoolImpl';
  const proxyName = 'SolvBTCYieldTokenMultiAssetPoolProxy';

  const versions = {
    dev_sepolia: ["v1.1"],
    sepolia: ["v1.1"],
    bsctest: ["v1.1"],
    bera: ["v1.1"],
  }
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const { proxy, newImpl, newImplName } = await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
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
