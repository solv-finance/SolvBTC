module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenMultiAssetPoolFactory = await ethers.getContractFactory("SolvBTCMultiAssetPool", deployer);
  const SolvBTCYieldTokenMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenMultiAssetPool = SolvBTCYieldTokenMultiAssetPoolFactory.attach(SolvBTCYieldTokenMultiAssetPoolAddress);
  
  
};

module.exports.tags = ['MultiAssetPoolDisableSft']
