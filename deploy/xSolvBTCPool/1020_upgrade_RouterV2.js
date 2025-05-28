const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const owner = deployer;

  const contractName = 'SolvBTCRouterV2';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {
    dev_sepolia: [ 'v2.1', 'v2.2' ],
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
  
  const params = {
    dev_sepolia: [
      '0x32Ea1777bC01977a91D15a1C540cbF29bE17D89D',  // xSolvBTC
      '0xe8C3edB09D1d155292BE0453d57bC3250a0084B6',  // SolvBTC
      '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',  // xSolvBTC PoolId
      (await deployments.get('XSolvBTCPoolProxy')).address,  // xSolvBTCPool
    ]
  }

  const currentPoolId = await solvBTCRouterV2.poolIds(params[network.name][0], params[network.name][1]);
  if (currentPoolId !== params[network.name][2]) {
    const setPoolIdTx = await solvBTCRouterV2.setPoolId(params[network.name][0], params[network.name][1], params[network.name][2]);
    console.log(`Set PoolInfo for xSolvBTC at tx: ${setPoolIdTx.hash}`);
    await setPoolIdTx.wait(1);
  }

  const currentPool = await solvBTCRouterV2.multiAssetPools(params[network.name][1]);
  if (currentPool !== params[network.name][3]) {
    const setPoolTx = await solvBTCRouterV2.setMultiAssetPool(params[network.name][1], params[network.name][3]);
    console.log(`Set MultiAssetPool for xSolvBTC at tx: ${setPoolTx.hash}`);
    await setPoolTx.wait(1);
  }

};

module.exports.tags = ['SolvBTCRouterV2_upgrade']
