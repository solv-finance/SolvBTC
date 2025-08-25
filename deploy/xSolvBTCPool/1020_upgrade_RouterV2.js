const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const owner = deployer;

  const contractName = 'SolvBTCRouterV2';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {
    dev_sepolia: [ 'v2.1', 'v2.2' ],
    sepolia: [ 'v2.1', 'v2.2' ],
    bsctest: [ 'v2.1', 'v2.2' ],
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
      upgrades: upgrades
    }
  );

  const SolvBTCRouterV2Factory = await ethers.getContractFactory("SolvBTCRouterV2", deployer);
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(proxy.address);

  const solvBTCAddress = require('./1099_export_xSolvBTCPoolInfos').SolvBTCAddresses[network.name];
  const xSolvBTCAddress = require('./1099_export_xSolvBTCPoolInfos').XSolvBTCInfos[network.name].token;
  const xSolvBTCPoolId = '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';
  const xSolvBTCPoolAddress = (await deployments.get('XSolvBTCPoolProxy')).address;
  
  const currentPoolId = await solvBTCRouterV2.poolIds(xSolvBTCAddress, solvBTCAddress);
  if (currentPoolId !== xSolvBTCPoolId) {
    const setPoolIdTx = await solvBTCRouterV2.setPoolId(xSolvBTCAddress, solvBTCAddress, xSolvBTCPoolId);
    console.log(`Set PoolInfo for xSolvBTC at tx: ${setPoolIdTx.hash}`);
    await setPoolIdTx.wait(1);
  }

  const currentPool = await solvBTCRouterV2.multiAssetPools(xSolvBTCAddress);
  if (currentPool !== xSolvBTCPoolAddress) {
    const setPoolTx = await solvBTCRouterV2.setMultiAssetPool(xSolvBTCAddress, xSolvBTCPoolAddress);
    console.log(`Set MultiAssetPool for xSolvBTC at tx: ${setPoolTx.hash}`);
    await setPoolTx.wait(1);
  }

};

module.exports.tags = ['SolvBTCRouterV2_upgrade']
