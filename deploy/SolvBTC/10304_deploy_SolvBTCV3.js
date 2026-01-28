const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactoryV3Factory = await ethers.getContractFactory('SolvBTCFactoryV3', deployer);
  const solvBTCFactoryV3Address = (await deployments.get('SolvBTCFactoryV3')).address;
  const solvBTCFactoryV3 = SolvBTCFactoryV3Factory.attach(solvBTCFactoryV3Address);

  const productType = 'Solv BTC';
  const productName = 'Solv BTC';
  const tokenName = 'Solv BTC';
  const tokenSymbol = 'SolvBTC';

  const owner = deployer;
  const blacklistManagers = {
    polygon: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    ink: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    hyperevm: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    tac: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    monad: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    stable: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    xlayer: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
  };
  const blacklistManager = blacklistManagers[network.name] || deployer;

  let proxyAddress = await solvBTCFactoryV3.getProxy(productType, productName);
  if (proxyAddress == ethers.constants.AddressZero) {
    const deployProxyTx = await solvBTCFactoryV3.deployProductProxy(productType, productName, tokenName, tokenSymbol, owner);
    console.log(`* INFO: Deploy SolvBTC at ${deployProxyTx.hash}`);
    await txWait(deployProxyTx);

    proxyAddress = await solvBTCFactoryV3.getProxy(productType, productName);
    console.log(`* INFO: SolvBTC deployed at ${colors.yellow(proxyAddress)}`);
    
  } else {
    console.log(`* INFO: SolvBTC already deployed at ${colors.yellow(proxyAddress)}`);
  }

  const SolvBTCV3Factory_ = await ethers.getContractFactory('SolvBTCV3_1', deployer);
  const solvBTCV3Address = await solvBTCFactoryV3.getProxy(productType, productName);
  const solvBTCV3 = SolvBTCV3Factory_.attach(solvBTCV3Address);

  const currentBlacklistManager = await solvBTCV3.blacklistManager();
  if (currentBlacklistManager.toLowerCase() == blacklistManager.toLowerCase()) {
    console.log(`* INFO: SolvBTC current blacklist manager is already ${currentBlacklistManager}`);
  } else {
    const setManagerTx = await solvBTCV3.updateBlacklistManager(blacklistManager);
    console.log(`* INFO: SolvBTC set blacklist manager to ${blacklistManager} at ${setManagerTx.hash}`);
    await txWait(setManagerTx);
  }
};

module.exports.tags = ['SolvBTCV3']
