const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCFactoryAddress = (await deployments.get('SolvBTCFactory')).address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const productType = 'Solv BTC';
  const productName = 'Solv BTC';
  const tokenName = 'Solv BTC';
  const tokenSymbol = 'SolvBTC';

  const proxyAddress = await solvBTCFactory.getProxy(productType, productName);
  if (proxyAddress == ethers.constants.AddressZero) {
    const deployProxyTx = await solvBTCFactory.deployProductProxy(productType, productName, tokenName, tokenSymbol);
    console.log(`* INFO: Deploy SolvBTC at ${deployProxyTx.hash}`);
    await txWait(deployProxyTx);
  } else {
    console.log(`* INFO: SolvBTC already deployed at ${proxyAddress}`);
  }

  const SolvBTCFactory_ = await ethers.getContractFactory('SolvBTC', deployer);
  const solvBTCAddress = await solvBTCFactory.getProxy(productType, productName);
  const solvBTC = SolvBTCFactory_.attach(solvBTCAddress);

  const poolAddressInSolvBTC = await solvBTC.solvBTCMultiAssetPool();
  if (poolAddressInSolvBTC == ethers.constants.AddressZero) {
    const solvBTCMultiAssetPool = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;
    const initializeV2Tx = await solvBTC.initializeV2(solvBTCMultiAssetPool);
    console.log(`* INFO: SolvBTC initializeV2 at ${initializeV2Tx.hash}`);
    await txWait(initializeV2Tx);
  } else {
    console.log(`* INFO: SolvBTC initializeV2 already executed`);
  }
};

module.exports.tags = ['SolvBTC']
