const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, network }) => {
  const { deployer } = await getNamedAccounts();

  const blacklistManager = deployer;

  const solvBTCYieldTokenInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const SolvBTCYieldTokenFactory = await ethers.getContractFactory('SolvBTCYieldTokenV3', deployer);

  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let erc20Address = solvBTCYieldTokenInfos[network.name][productName].erc20;
    let solvBTCYieldToken = SolvBTCYieldTokenFactory.attach(erc20Address);

    const currentManager = await solvBTCYieldToken.blacklistManager();
    if (currentManager == blacklistManager) {
      console.log(`* INFO: ${productName} current blacklist manager is already ${currentManager}`);
    } else {
      const setManagerTx = await solvBTCYieldToken.updateBlacklistManager(blacklistManager);
      console.log(`* INFO: ${productName} set blacklist manager to ${blacklistManager} at ${setManagerTx.hash}`);
      await txWait(setManagerTx);
    }

  }
};

module.exports.tags = ['SolvBTCYT_SetBlacklistManager'];
