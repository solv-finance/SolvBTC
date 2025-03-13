const transparentUpgrade = require("../utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const BroRouterFactory = await ethers.getContractFactory(
    "BRORouter",
    deployer
  );
  const broRouterAddress = (await deployments.get("BRORouterProxy")).address;
  const broRouter = BroRouterFactory.attach(broRouterAddress);

  const sft = "0x982d50f8557d57b748733a3fc3d55aef40c46756";
  const sftSlot =
    "73231647582029612737074404226959872200187963607849152869643358116207496900469";
  const broToken = (await deployments.get("BRO-SolvBTC-13MAR2026")).address;

  const setBroTokenTx = await broRouter.setBroToken(sft, sftSlot, broToken);
  console.log(`Set BroToken ${broToken} at tx: ${setBroTokenTx.hash}`);
  await setBroTokenTx.wait(1);
};

module.exports.tags = ["SetBroToken"];
