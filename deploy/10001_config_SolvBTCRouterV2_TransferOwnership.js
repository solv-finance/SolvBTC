const transparentUpgrade = require("./utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const newOwner = "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D";

  const SolvBTCRouterV2Factory = await ethers.getContractFactory("SolvBTCRouterV2", deployer);
  const solvBTCRouterV2Address = (await deployments.get("SolvBTCRouterV2Proxy")).address;
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(solvBTCRouterV2Address);

  let owner = await solvBTCRouterV2.owner();
  let pendingOwner = await solvBTCRouterV2.pendingOwner();
  if (owner != newOwner && pendingOwner != newOwner) {
    const transferOwnershipTx = await solvBTCRouterV2.transferOwnership(newOwner);
    console.log(`* SolvBTCRouterV2 transferring ownership to ${newOwner} at tx ${transferOwnershipTx.hash}`);
    await txWait(transferOwnershipTx);
  }
  if (owner != newOwner) {
    assert.equal(await solvBTCRouterV2.pendingOwner(), newOwner);
  }
  console.log(`* SolvBTCRouterV2 ownership has been transferred to ${newOwner}`);

};

module.exports.tags = ["SolvBTCRouterV2_TransferOwnership"];
