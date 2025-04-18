const transparentUpgrade = require('../utils/transparentUpgrade');
const gasTracker = require('../utils/gasTracker');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const gasPrice = await gasTracker.getGasPrice(network.name);

  const governor = deployer;
  const market = require('./10099_export_SolvBTCInfos').OpenFundMarketAddresses[network.name];
  const solvBTCMultiAssetPool = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;

  const contractName = 'SolvBTCRouter';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {}
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const { proxy, newImpl, newImplName } = await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
      // gasPrice: gasPrice,
      log: true
    },
    {
      initializer: { 
        method: "initialize", 
        args: [ governor, market, solvBTCMultiAssetPool ] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['SolvBTCRouter']
