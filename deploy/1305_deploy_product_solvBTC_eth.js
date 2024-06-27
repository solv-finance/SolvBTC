const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0x7d6c3860b71cf82e2e1e8d5d104cf77f5b84f93a";
  const wrappedSlot =
    "85402499252096164095609232758358824605868392495188266406491311694532023267832";
  const navOracle = "0xf940230a3357971fe0f22e8c144bc70d9fa91d43";

  await factoryHelpers.deployProxy(
    productType,
    productName,
    tokenName,
    tokenSymbol,
    wrappedSft,
    wrappedSlot,
    navOracle
  );
};

module.exports.tags = ["solvBTC_eth"];
