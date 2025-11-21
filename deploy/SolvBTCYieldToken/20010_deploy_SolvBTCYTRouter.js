const transparentUpgrade = require('../utils/transparentUpgrade');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const governor = deployer;
  const market = require('../SolvBTC/10099_export_SolvBTCInfos').OpenFundMarketAddresses[network.name];
  const solvBTCYieldTokenMultiAssetPool = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;

  const contractName = 'SolvBTCRouter';
  const firstImplName = 'SolvBTCYieldTokenRouterImpl';
  const proxyName = 'SolvBTCYieldTokenRouterProxy';

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
        args: [ governor, market, solvBTCYieldTokenMultiAssetPool ] 
      },
      upgrades: upgrades
    }
  );

};

module.exports.tags = ['SolvBTCYTRouter']
