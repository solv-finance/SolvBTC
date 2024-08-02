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
    let addSftTx = await solvBTCYieldTokenMultiAssetPool.addSftSlotOnlyAdmin(
      info.sft, info.slot, info.erc20, info.holdingValueSftId
    );
    console.log(`* INFO: SolvBTCYieldTokenMultiAssetPool add sft at ${addSftTx.hash}`);
    await txWait(addSftTx);
  }
};

module.exports.tags = ['SetSolvBTCYieldTokenMultiAssetPool']
