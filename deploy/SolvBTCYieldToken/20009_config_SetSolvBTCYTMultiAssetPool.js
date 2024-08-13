const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenMultiAssetPoolFactory = await ethers.getContractFactory('SolvBTCMultiAssetPool', deployer);
  const solvBTCYieldTokenMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenMultiAssetPool = SolvBTCYieldTokenMultiAssetPoolFactory.attach(solvBTCYieldTokenMultiAssetPoolAddress);

  const productInfos = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  for (let productName in productInfos[network.name]) {
    let info = productInfos[network.name][productName];
    let erc20InPool = await solvBTCYieldTokenMultiAssetPool.getERC20(info.sft, info.slot);

    if (erc20InPool == ethers.constants.AddressZero) {
      let addSftTx = await solvBTCYieldTokenMultiAssetPool.addSftSlotOnlyAdmin(
        info.sft, info.slot, info.erc20, info.holdingValueSftId
      );
      console.log(`* INFO: SolvBTCYieldTokenMultiAssetPool add sft for ${info.erc20} at ${addSftTx.hash}`);
      await txWait(addSftTx);
    } else {
      console.log(`* INFO: ${erc20InPool} already added to SolvBTCYieldTokenMultiAssetPool`);
    }
  }
};

module.exports.tags = ['SetSolvBTCYTMultiAssetPool']

