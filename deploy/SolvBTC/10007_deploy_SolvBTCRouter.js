const transparentUpgrade = require('../utils/transparentUpgrade');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const governor = deployer;
  const market = require('./10099_export_SolvBTCInfos').OpenFundMarketAddresses[network.name];
  const solvBTCMultiAssetPool = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;

  const contractName = 'SolvBTCRouter';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {
    dev_sepolia: ["v1.1", "v1.2"],
    sepolia: ["v1.1", "v1.2"],
    bsctest: ["v1.1", "v1.2"],
    bera: ["v1.1"],
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
        args: [ governor, market, solvBTCMultiAssetPool ] 
      },
      upgrades: upgrades
    }
  );

  // Set FeeManager address
  const feeManagerAddress = (await deployments.get("FeeManagerProxy")).address;
  const SolvBTCRouterFactory = await ethers.getContractFactory("SolvBTCRouter", deployer);
  const solvBTCRouter = SolvBTCRouterFactory.attach(proxy.address);
  const currentFeeManager = await solvBTCRouter.feeManager();
  if (currentFeeManager != feeManagerAddress) {
    const tx = await solvBTCRouter.setFeeManager(feeManagerAddress);
    console.log(`* SolvBTCRouter: SetFeeManager for ${feeManagerAddress} at tx ${tx.hash}`);
    await txWait(tx);
  }
};

module.exports.tags = ['SolvBTCRouter']
