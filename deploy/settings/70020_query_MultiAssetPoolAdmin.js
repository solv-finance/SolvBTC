const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");
const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const solvBTCMultiAssetPoolAddress = require("../SolvBTC/10099_export_SolvBTCInfos").SolvBTCMultiAssetPoolAddresses[network.name];
  const lstMultiAssetPoolAddress = require("../SolvBTCYieldToken/20099_export_SolvBTCYTInfos").SolvBTCYieldTokenMultiAssetPoolAddresses[network.name];
  const xSolvBTCPoolAddress = (await deployments.getOrNull('XSolvBTCPoolProxy'))?.address;

  const MultiAssetPoolFactory = await ethers.getContractFactory("SolvBTCMultiAssetPool", deployer);
  const XSolvBTCPoolFactory = await ethers.getContractFactory("XSolvBTCPool", deployer);

  if (solvBTCMultiAssetPoolAddress) {
    const solvBTCPool = MultiAssetPoolFactory.attach(solvBTCMultiAssetPoolAddress);
    console.log(`SolvBTC MultiAssetPool ${solvBTCMultiAssetPoolAddress}`);
    console.log(await solvBTCPool.admin());
  }

  if (lstMultiAssetPoolAddress) {
    const lstPool = MultiAssetPoolFactory.attach(lstMultiAssetPoolAddress);
    console.log(`SolvBTCYieldToken MultiAssetPool ${lstMultiAssetPoolAddress}`);
    console.log(await lstPool.admin());
  }

  if (xSolvBTCPoolAddress) {
    const xSolvBTCPool = XSolvBTCPoolFactory.attach(xSolvBTCPoolAddress);
    console.log(`XSolvBTCPool ${xSolvBTCPoolAddress}`);
    console.log(await xSolvBTCPool.admin());
  }

};

module.exports.tags = ["Query_MultiAssetPoolAdmin"];
