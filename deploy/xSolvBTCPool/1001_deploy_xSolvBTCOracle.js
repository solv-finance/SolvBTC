const { ethers } = require('hardhat');
const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const params = {
    dev_sepolia: {
      currentNav: ethers.utils.parseUnits('1.05', 18), 
      navDecimals: 18,
    },
  };

  const contractName = 'XSolvBTCOracle';
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
          params[network.name].currentNav, params[network.name].navDecimals,
        ] 
      },
      upgrades: upgrades
    }
  );

};

module.exports.tags = ['xSolvBTCOracle']
