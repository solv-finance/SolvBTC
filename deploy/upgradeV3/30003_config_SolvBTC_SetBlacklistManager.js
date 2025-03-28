const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, network }) => {
  const { deployer } = await getNamedAccounts();

  const blacklistManager = deployer;

  const SolvBTCFactory = await ethers.getContractFactory('SolvBTCV3', deployer);
  const solvBTCAddress = require('../SolvBTC/10999_export_SolvBTCInfos').SolvBTCInfos[network.name].erc20;
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);

  const currentManager = await solvBTC.blacklistManager();
  if (currentManager == blacklistManager) {
    console.log(`* INFO: SolvBTC current blacklist manager is already ${currentManager}`);
  } else {
    const setManagerTx = await solvBTC.updateBlacklistManager(blacklistManager);
    console.log(`* INFO: SolvBTC set blacklist manager to ${blacklistManager} at ${setManagerTx.hash}`);
    await txWait(setManagerTx);
  }

};

module.exports.tags = ['SolvBTC_SetBlacklistManager'];
