const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCMultiAssetPoolAddress = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;
  const solvBTCMultiAssetPool = SolvBTCMultiAssetPoolFactory.attach(solvBTCMultiAssetPoolAddress);

  const solvBTCInfos = require('./10399_export_SolvBTCV3Infos').SolvBTCInfos;

  const erc20InPool = await solvBTCMultiAssetPool.getERC20(solvBTCInfos[network.name].sft, solvBTCInfos[network.name].slot);
  if (erc20InPool == ethers.constants.AddressZero) {
    const addSftTx = await solvBTCMultiAssetPool.addSftSlotOnlyAdmin(
      solvBTCInfos[network.name].sft, solvBTCInfos[network.name].slot, 
      solvBTCInfos[network.name].erc20, solvBTCInfos[network.name].holdingValueSftId
    );
    console.log(`* INFO: SolvBTCMultiAssetPool add sft at ${addSftTx.hash}`);
    await txWait(addSftTx);
  } else {
    console.log(`* INFO: ${erc20InPool} already added to SolvBTCMultiAssetPool`);
  }

};

module.exports.tags = ['SolvBTCV3_SetMultiAssetPool']
