const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");

module.exports = async ({ getNamedAccounts, network }) => {
  const deployer = await hre.zksyncEthers.getWallet();

  const blacklistManager = "0x3295836ef0D7241b1DCE65b364A5D8a8De1B93b6";

  const SolvBTCFactory = await ethers.getContractFactory(
    "SolvBTCV3_1",
    deployer
  );
  const solvBTCAddress = require("../SolvBTC/10099_export_SolvBTCInfos")
    .SolvBTCInfos[network.name].erc20;
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);

  const currentManager = await solvBTC.blacklistManager();
  if (currentManager == blacklistManager.address) {
    console.log(
      `* INFO: SolvBTC current blacklist manager is already ${currentManager}`
    );
  } else {
    const setManagerTx = await solvBTC.updateBlacklistManager(blacklistManager);
    console.log(
      `* INFO: SolvBTC set blacklist manager to ${blacklistManager.address} at ${setManagerTx.hash}`
    );
    await txWait(setManagerTx);
  }
};

module.exports.tags = ["SolvBTC_SetBlacklistManager"];
