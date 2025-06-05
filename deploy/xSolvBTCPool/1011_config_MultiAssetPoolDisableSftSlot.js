module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenMultiAssetPoolFactory = await ethers.getContractFactory("SolvBTCMultiAssetPool", deployer);
  const SolvBTCYieldTokenMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenMultiAssetPool = SolvBTCYieldTokenMultiAssetPoolFactory.attach(SolvBTCYieldTokenMultiAssetPoolAddress);
  
  const sft = require('./1099_export_xSolvBTCPoolInfos').XSolvBTCInfos[network.name].sft;
  const slot = require('./1099_export_xSolvBTCPoolInfos').XSolvBTCInfos[network.name].slot;
  
  const isSftSlotAllowed = await solvBTCYieldTokenMultiAssetPool.isSftSlotDepositAllowed(sft, slot);
  if (!isSftSlotAllowed) {
    console.log(`sft ${sft} slot ${slot} already disabled`);
  } else {
    const disableSftTx = await solvBTCYieldTokenMultiAssetPool.changeSftSlotAllowedOnlyAdmin(sft, slot, false, false);
    console.log(`disableSftTx ${disableSftTx.hash}`);
    await disableSftTx.wait(1);
  }
};

module.exports.tags = ['MultiAssetPoolDisableSftSlot']
