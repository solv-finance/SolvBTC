const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");
const { network } = require("hardhat");

const oldAdmin = "0x55C09707Fd7aFD670e82A62FaeE312903940013E";
const newAdmin = "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D";

const isAdmin = async (contract, wallet) => {
  const adminRole = await contract.DEFAULT_ADMIN_ROLE();
  return await contract.hasRole(adminRole, wallet);
};

const transferAdminAndOwner = async (productName, token) => {
  console.log(
    `Start handling tasks for ${colors.yellow(productName)} - ${
      token.address
    } on ${colors.yellow(network.name)}`
  );

  const ADMIN_ROLE_ID = await token.DEFAULT_ADMIN_ROLE();

  // Grant admin role to newAdmin
  if (!(await isAdmin(token, newAdmin))) {
    const grantTx = await token.grantRole(ADMIN_ROLE_ID, newAdmin);
    console.log(
      `* ${colors.yellow(
        productName
      )}: Granting admin role to ${newAdmin} at tx ${grantTx.hash}`
    );
    await txWait(grantTx);
  }
  assert.equal(await isAdmin(token, newAdmin), true);
  console.log(
    `* ${colors.yellow(productName)}: ${newAdmin} has been granted admin role`
  );

  // Renounce admin role by oldAdmin
  if (await isAdmin(token, oldAdmin)) {
    const renounceTx = await token.renounceRole(ADMIN_ROLE_ID, oldAdmin);
    console.log(
      `* ${colors.yellow(
        productName
      )}: Renouncing admin role for ${oldAdmin} at tx ${renounceTx.hash}`
    );
    await txWait(renounceTx);
  }
  assert.equal(await isAdmin(token, oldAdmin), false);
  console.log(
    `* ${colors.yellow(productName)}: ${oldAdmin} has renounced admin role`
  );

  // Transfer ownership to newAdmin
  let owner = await token.owner();
  let pendingOwner = await token.pendingOwner();
  if (owner != newAdmin && pendingOwner != newAdmin) {
    const transferOwnershipTx = await token.transferOwnership(newAdmin);
    console.log(
      `* ${colors.yellow(
        productName
      )}: Transferring ownership to ${newAdmin} at tx ${
        transferOwnershipTx.hash
      }`
    );
    await txWait(transferOwnershipTx);
  }
  assert.equal(await token.pendingOwner(), newAdmin);
  console.log(
    `* ${colors.yellow(
      productName
    )}: Ownership has been transferred to ${newAdmin}`
  );
};

module.exports = async ({ getNamedAccounts, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactory = await ethers.getContractFactory("SolvBTC", deployer);
  const solvBTCAddress = require("../SolvBTC/10999_export_SolvBTCInfos")
    .SolvBTCInfos[network.name].erc20;
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);

  // SolvBTC
  await transferAdminAndOwner("SolvBTC", solvBTC);

  // SolvBTCYieldTokens
  const solvBTCYieldTokenInfos =
    require("../SolvBTCYieldToken/20999_export_SolvBTCYTInfos").SolvBTCYieldTokenInfos;
  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let yieldTokenAddress =
      solvBTCYieldTokenInfos[network.name][productName].erc20;
    let yieldToken = SolvBTCFactory.attach(yieldTokenAddress);
    await transferAdminAndOwner(productName, yieldToken);
  }
};

module.exports.tags = ["TransferAdminAndOwner"];
