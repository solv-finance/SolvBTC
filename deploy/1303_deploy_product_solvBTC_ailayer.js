const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "";
  const wrappedSlot = "";
  const navOracle = "";

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

module.exports.tags = ["solvBTC_bnb"];
