const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryV3Factory = await ethers.getContractFactory('SolvBTCFactoryV3', deployer);
  const solvBTCYieldTokenFactoryV3Address = (await deployments.get('SolvBTCYieldTokenFactoryV3')).address;
  const solvBTCYieldTokenFactoryV3 = SolvBTCYieldTokenFactoryV3Factory.attach(solvBTCYieldTokenFactoryV3Address);

  const productType = "SolvBTC Yield Token";
  const productName = "BTC+";  // dev: "BTC_plus"
  const tokenName = "BTC+";
  const tokenSymbol = "BTC+";

  const blacklistManagers = {
    mainnet: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    bsc: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    avax: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    arb: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    base: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    bob: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    bera: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    soneium: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    polygon: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    ink: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    hyperevm: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    tac: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    rootstock: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
    xlayer: "0xDC3a91D2fa7e1d36B1baA0852f5d8734bd209D02",
  };
  const blacklistManager = blacklistManagers[network.name] || deployer;

  let proxyAddress = await solvBTCYieldTokenFactoryV3.getProxy(productType, productName);
  if (proxyAddress == ethers.constants.AddressZero) {
    const deployProxyTx = await solvBTCYieldTokenFactoryV3.deployProductProxy(productType, productName, tokenName, tokenSymbol, deployer);
    console.log(`* INFO: Deploy ${tokenSymbol} at ${deployProxyTx.hash}`);
    await txWait(deployProxyTx);

    proxyAddress = await solvBTCYieldTokenFactoryV3.getProxy(productType, productName);
    console.log(`* INFO: ${tokenSymbol} deployed at ${colors.yellow(proxyAddress)}`);

  } else {
    console.log(`* INFO: ${tokenSymbol} already deployed at ${colors.yellow(proxyAddress)}`);
  }

  const SolvBTCYieldTokenV3Factory_ = await ethers.getContractFactory('SolvBTCYieldTokenV3', deployer);
  const solvBTCYieldTokenV3Address = await solvBTCYieldTokenFactoryV3.getProxy(productType, productName);
  const solvBTCYieldTokenV3 = SolvBTCYieldTokenV3Factory_.attach(solvBTCYieldTokenV3Address);

  // set oracle address for SolvBTCYieldToken
  const oracleAddressInSolvBTC = await solvBTCYieldTokenV3.getOracle();
  if (oracleAddressInSolvBTC == ethers.constants.AddressZero) {
    const solvBTCYieldPoolOracleAddress = (await deployments.get('SolvBTCYieldTokenOracleForSFTProxy')).address;
    const setOracleTx = await solvBTCYieldTokenV3.setOracle(solvBTCYieldPoolOracleAddress);
    console.log(`* INFO: ${tokenSymbol} setOracle ${solvBTCYieldPoolOracleAddress} at ${setOracleTx.hash}`);
    await txWait(setOracleTx);
  } else {
    console.log(`* INFO: ${tokenSymbol} oracle already set`);
  }

  // set blacklist manager for SolvBTCYieldToken
  const currentBlacklistManager = await solvBTCYieldTokenV3.blacklistManager();
  if (currentBlacklistManager.toLowerCase() == blacklistManager.toLowerCase()) {
    console.log(`* INFO: ${tokenSymbol} current blacklist manager is already ${currentBlacklistManager}`);
  } else {
    const setManagerTx = await solvBTCYieldTokenV3.updateBlacklistManager(blacklistManager);
    console.log(`* INFO: ${tokenSymbol} set blacklist manager to ${blacklistManager} at ${setManagerTx.hash}`);
    await txWait(setManagerTx);
  }
};

module.exports.tags = ['BTC+']
