const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0xd20078bd38abc1378cb0a3f6f0b359c4d8a7b90e";
  const wrappedSlot = "39475026322910990648776764986670533412889479187054865546374468496663502783148";
  const navOracle = "0xc09022c379ee2bee0da72813c0c84c3ed8521251";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['solvBTC_arb']