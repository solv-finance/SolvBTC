const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCYieldTokenFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const productType = 'SolvBTC Yield Token';
  const productName = 'SolvBTC Ethena';
  const tokenName = 'SolvBTC Ethena';
  const tokenSymbol = 'SolvBTC.ENA';

  const deployProxyTx = await solvBTCYieldTokenFactory.deployProductProxy(productType, productName, tokenName, tokenSymbol);
  console.log(`* INFO: Deploy SolvBTC.ENA at ${deployProxyTx.hash}`);
  await txWait(deployProxyTx);

  const SolvBTCYieldTokenFactory_ = await ethers.getContractFactory('SolvBTCYieldToken', deployer);
  const solvBTCYieldTokenAddress = await solvBTCYieldTokenFactory.getProxy(productType, productName);
  const solvBTCYieldToken = SolvBTCYieldTokenFactory_.attach(solvBTCYieldTokenAddress);

  // execute `initializeV2` for SolvBTCYieldToken
  const solvBTCYieldPoolMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const initializeV2Tx = await solvBTCYieldToken.initializeV2(solvBTCYieldPoolMultiAssetPoolAddress);
  console.log(`* INFO: SolvBTC.ENA initializeV2 at ${initializeV2Tx.hash}`);
  await txWait(initializeV2Tx);

  // set oracle address for SolvBTCYieldToken
  const solvBTCYieldPoolOracleAddress = (await deployments.get('SolvBTCYieldTokenOracleForSFTProxy')).address;
  const setOracleTx = await solvBTCYieldToken.setOracle(solvBTCYieldPoolOracleAddress);
  console.log(`* INFO: ${solvBTCYieldToken} setOracle ${solvBTCYieldPoolOracleAddress} at ${setOracleTx.hash}`);
  await txWait(setOracleTx);
};

module.exports.tags = ['SolvBTC_ENA']
