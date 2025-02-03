const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");
const { network } = require("hardhat");


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
  if (owner != newAdmin) {
    assert.equal(await token.pendingOwner(), newAdmin);
  }
  console.log(
    `* ${colors.yellow(
      productName
    )}: Ownership has been transferred to ${newAdmin}`
  );
};

module.exports = async ({ getNamedAccounts, network }) => {
  const { deployer } = await getNamedAccounts();
  // TODO: change to bridge address
  const solvBTCBridge = "0xB12979Ff302Ac903849948037A51792cF7186E8e"; // layer zero on bera

  const SolvBTCFactory = await ethers.getContractFactory("SolvBTC", deployer);
  const solvBTCAddress = require("../SolvBTC/10999_export_SolvBTCInfos")
    .SolvBTCInfos[network.name].erc20;
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);

  const SOLVBTC_MINTER_ROLE = await solvBTC.SOLVBTC_MINTER_ROLE();

  const grantTx = await solvBTC.grantRole(SOLVBTC_MINTER_ROLE, solvBTCBridge);
  console.log(
    `* ${colors.yellow(
      "SolvBTC"
    )}: Granting mint role to ${solvBTCBridge} at tx ${grantTx.hash}`
  );
  await txWait(grantTx);

  // SolvBTCYieldTokens
  const solvBTCYieldTokenBridge = "0x94DaBd84Cd36c4D364FcDD5CdABf41E73dBc99e6"; // layer zero on bera
  const solvBTCYieldTokenInfos =
    require("../SolvBTCYieldToken/20999_export_SolvBTCYTInfos").SolvBTCYieldTokenInfos;
  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let yieldTokenAddress =
      solvBTCYieldTokenInfos[network.name][productName].erc20;
    let yieldToken = SolvBTCFactory.attach(yieldTokenAddress);
    const SOLVBTC_MINTER_ROLE = await yieldToken.SOLVBTC_MINTER_ROLE();
    const grantTx = await yieldToken.grantRole(
      SOLVBTC_MINTER_ROLE,
      solvBTCYieldTokenBridge
    );
    console.log(
      `* ${colors.yellow(
        productName
      )}: Granting mint role to ${solvBTCYieldTokenBridge} at tx ${
        grantTx.hash
      }`
    );
    await txWait(grantTx);
  }
};

module.exports.tags = ["GrantMintRole"];
