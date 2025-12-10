const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");
const { network } = require("hardhat");

const marketAddress = require("../SolvBTC/10099_export_SolvBTCInfos").OpenFundMarketAddresses[network.name];

const poolIds = {
  mainnet: '0x8c30d7ea7c682f3f8ec65beaba1c21755fc5c6976f4c979da06abee7c5890e8f',
  bsc: '0xd3b1d3c5c203cd23f4fc80443559069b1e313302a10a86d774345dc4ad81b0f6',
  arb: '0x88b47de44e1954c8d5849c964ac424f6e636ca5b89f0eae4e47902bf5678841f',
  avax: '0x2af9049acd74a38a57bf5299463042bd2b9a8d525bfbbe640f84d099651a77fc',
  base: '0x8062a56325411007013e749ed9f1a2b39e676171122e88d5230012879af9c54b',
  bob: '0xad64f76b02f1758f87254bf52340452a6589bc7975ba424edda8585384bfa736',
  bera: '0x7f712c24cedabb020f303f07650d19c94a93d71ca928ed614ece8b15aef85150',
  hyperevm: '0x3d531b19bb21df9f08e2327e0acf63dd9ae416e782acbc3683cfd1851a536d15',
}

const transferAdminAndOwner = async (productName, token) => {
  console.log(
    `Start handling tasks for ${colors.yellow(productName)} - ${token.address} on ${colors.yellow(network.name)}`
  );

  const ADMIN_ROLE_ID = await token.DEFAULT_ADMIN_ROLE();
  const newAdmin = getNewAdmin(network.name);

  // Grant admin role to newAdmin
  if (!(await isAdmin(token, newAdmin))) {
    const grantTx = await token.grantRole(ADMIN_ROLE_ID, newAdmin);
    console.log(`* ${colors.yellow(productName)}: Granting admin role to ${newAdmin} at tx ${grantTx.hash}`);
    await txWait(grantTx);
  }
  assert.equal(await isAdmin(token, newAdmin), true);
  console.log(`* ${colors.yellow(productName)}: ${newAdmin} has been granted admin role`);

  // Renounce admin role by oldAdmin
  if (await isAdmin(token, oldAdmin)) {
    const renounceTx = await token.renounceRole(ADMIN_ROLE_ID, oldAdmin);
    console.log(`* ${colors.yellow(productName)}: Renouncing admin role for ${oldAdmin} at tx ${renounceTx.hash}`);
    await txWait(renounceTx);
  }
  assert.equal(await isAdmin(token, oldAdmin), false);
  console.log(`* ${colors.yellow(productName)}: ${oldAdmin} has renounced admin role`);

  // Transfer ownership to newAdmin
  let owner = await token.owner();
  let pendingOwner = await token.pendingOwner();
  if (owner != newAdmin && pendingOwner != newAdmin) {
    const transferOwnershipTx = await token.transferOwnership(newAdmin);
    console.log(`* ${colors.yellow(productName)}: Transferring ownership to ${newAdmin} at tx ${transferOwnershipTx.hash}`);
    await txWait(transferOwnershipTx);
  }
  if (owner != newAdmin) {
    assert.equal(await token.pendingOwner(), newAdmin);
  }
  console.log(`* ${colors.yellow(productName)}: Ownership has been transferred to ${newAdmin}`);
};

module.exports = async ({ getNamedAccounts, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactory = await ethers.getContractFactory("SolvBTC", deployer);

  // SolvBTC
  const solvBTCInfo = require("../SolvBTC/10399_export_SolvBTCV3Infos").SolvBTCInfos[network.name];
  if (solvBTCInfo) {
    const solvBTC = SolvBTCFactory.attach(solvBTCInfo.erc20);
    await transferAdminAndOwner("SolvBTC", solvBTC);
  }

  // SolvBTCYieldTokens
  const solvBTCYieldTokenInfos = require("../SolvBTCYieldToken/20399_export_SolvBTCYTV3Infos").SolvBTCYieldTokenInfos;
  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let yieldTokenAddress = solvBTCYieldTokenInfos[network.name][productName].erc20;
    let yieldToken = SolvBTCFactory.attach(yieldTokenAddress);
    await transferAdminAndOwner(productName, yieldToken);
  }
};

module.exports.tags = ["TransferAdminAndOwnerV3"];
