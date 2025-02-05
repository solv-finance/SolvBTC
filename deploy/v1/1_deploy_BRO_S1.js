const transparentUpgrade = require('./utils/transparentUpgrade');
const gasTracker = require('./utils/gasTracker');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const tokenName = "Solv Bitcoin Reserve Offering Season 1";
  const tokenSymbol = "broSolv-S1";
  const wrappedSftAddress = "0x1bda9d2d280054c5cf657b538751dd3bb88671e3";
  const wrappedSftSlot_ = 51168931530860486813172479863111136415129664424723786871686682088452636497339;
  const exchangeRate = ethers.utils.parseEther('2000000');
  const solvBTCAddress = {
    dev_sepolia: "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6",
  };

  const contractName = 'BitcoinReserveOffering';
  const firstImplName = 'BitcoinReserveOfferingImpl';
  const proxyName = contractName + 'Proxy';

  const versions = {}
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const 

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
        args: [ governor, market[network.name], factory ] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['BRO']
