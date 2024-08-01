const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCMultiAssetPoolAddress = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;
  const solvBTCMultiAssetPool = SolvBTCMultiAssetPoolFactory.attach(solvBTCMultiAssetPoolAddress);

  const solvBTCInfos = require('./10999_export_SolvBTCInfos').SolvBTCInfos;

  const addSftTx = await solvBTCMultiAssetPool.addSftSlotOnlyAdmin(
    solvBTCInfos[network.name].sft, solvBTCInfos[network.name].slot, 
    solvBTCInfos[network.name].erc20, solvBTCInfos[network.name].holdingValueSftId
  );
  console.log(`* INFO: SolvBTCMultiAssetPool add sft at ${addSftTx.hash}`);
  await txWait(addSftTx);
};

module.exports.tags = ['SetSolvBTCMultiAssetPool']
