const transparentUpgrade = require('../utils/transparentUpgrade');
const gasTracker = require('../utils/gasTracker');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const params = {
    rootstock_test: {
      wrapToken: '0x60680f8921E50c25A8030F4175C5d12C91Ee1Fe9',
      solvBTC: '0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9',
      router: '0x4f6A3A62f6AbeC2b9a9540d1e5898f2E3bed5A81',
    },
    rootstock: {
      wrapToken: '0x542fDA317318eBF1d3DEAf76E0b632741A7e677d',
      solvBTC: '0x541FD749419CA806a8bc7da8ac23D346f2dF8B77',
      router: '0xeFD6F956d68ce2A2338D3c0b12cC51Fd0504D233',
    }
  };

  const contractName = 'NativeDeposit';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {}
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const param = params[network.name];
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
        args: [ param.wrapToken, param.solvBTC, param.router ] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['NativeDeposit']
