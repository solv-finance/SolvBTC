const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0x6b2e555b6c17bfbba251cc3cde084071f4a7ef38";
  const wrappedSlot =
    "107692205666376871342025758595633836733167145887938195151240007951602293268562";
  const navOracle = "0x833154f6551a1b98518e9062937b657bc60bfa8c";

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

module.exports.tags = ["solvBTC_ailayer"];
