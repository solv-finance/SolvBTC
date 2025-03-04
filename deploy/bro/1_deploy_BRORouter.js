const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const governor = deployer;
  const market = {
    dev_sepolia: '0x109198Eb8BD3064Efa5d0711b505f59cFd77de18',
    sepolia: '0x91967806F47e2c6603C9617efd5cc91Bc2A7473E',
  };

  const contractName = 'BRORouter';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {
    dev_sepolia: ['v1.0'],
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
        args: [ governor, market[network.name] ] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['BRORouter']
