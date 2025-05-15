const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const params = {
    dev_sepolia: {
      solvBTC: '0xe8C3edB09D1d155292BE0453d57bC3250a0084B6',
      xSolvBTC: '0x32Ea1777bC01977a91D15a1C540cbF29bE17D89D',
      feeRecipient: deployer,
      withdrawFeeRate: 100,  // 1%
    },
  };

  const contractName = 'XSolvBTCPool';
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
      log: true
    },
    {
      initializer: { 
        method: "initialize", 
        args: [ 
          params[network.name].solvBTC, params[network.name].xSolvBTC, 
          params[network.name].feeRecipient, params[network.name].withdrawFeeRate 
        ] 
      },
      upgrades: upgrades
    }
  );

};

module.exports.tags = ['xSolvBTCPool']
