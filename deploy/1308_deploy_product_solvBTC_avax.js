const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0x6b2e555b6c17bfbba251cc3cde084071f4a7ef38";
  const wrappedSlot =
    "11855698383361531140241834848840694583099560042595010827827423787557845170628";
  const navOracle = "0x1b4a98cd14f6d42975f1f10ef15551a818a5f2bf";

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

module.exports.tags = ["solvBTC_avax"];
