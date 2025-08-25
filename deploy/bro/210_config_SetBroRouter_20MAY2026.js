const transparentUpgrade = require("../utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const BroRouterFactory = await ethers.getContractFactory(
    "BRORouter",
    deployer
  );
  const broRouterAddress = (await deployments.get("BRORouterProxy")).address;
  const broRouter = BroRouterFactory.attach(broRouterAddress);

  const broInfos = {
    mainnet: {
      symbol: "BRO-SOLV-20MAY2026",
      wrappedSft: "0x982d50f8557d57b748733a3fc3d55aef40c46756",
      wrappedSlot:
        "59941817680784839512955531781142811538110068167415369884908527049217128305967",
    },
  };

  const broInfo = broInfos[network.name];
  const broToken = (await deployments.get(broInfo.symbol)).address;

  const currentBroToken = await broRouter.broTokens(
    broInfo.wrappedSft,
    broInfo.wrappedSlot
  );
  if (currentBroToken.toLowerCase() == broToken.toLowerCase()) {
    console.log(`BroToken ${broToken} already set`);
  } else {
    const setBroTokenTx = await broRouter.setBroToken(
      broInfo.wrappedSft,
      broInfo.wrappedSlot,
      broToken
    );
    console.log(`Set BroToken ${broToken} at tx: ${setBroTokenTx.hash}`);
    await setBroTokenTx.wait(1);
  }
};

module.exports.tags = ["SetBroRouter_20MAY2026"];
