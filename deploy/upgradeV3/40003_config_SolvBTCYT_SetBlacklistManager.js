const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, network }) => {
  const deployer = await hre.zksyncEthers.getWallet();

  const blacklistManager = deployer;

  const solvBTCYieldTokenInfos = require('../SolvBTCYieldToken/20099_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const SolvBTCYieldTokenFactory = await ethers.getContractFactory('SolvBTCYieldTokenV3_1', deployer);

  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let erc20Address = solvBTCYieldTokenInfos[network.name][productName].erc20;
    let solvBTCYieldToken = SolvBTCYieldTokenFactory.attach(erc20Address);

    const currentManager = await solvBTCYieldToken.blacklistManager();
    if (currentManager == blacklistManager.address) {
      console.log(`* INFO: ${productName} current blacklist manager is already ${currentManager}`);
    } else {
      const setManagerTx = await solvBTCYieldToken.updateBlacklistManager(blacklistManager);
      console.log(`* INFO: ${productName} set blacklist manager to ${blacklistManager.address} at ${setManagerTx.hash}`);
      await txWait(setManagerTx);
    }
  }
};

module.exports.tags = ['SolvBTCYT_SetBlacklistManager'];
