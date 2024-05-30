const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Ethena";
  const tokenName = "SolvBTC Ethena";
  const tokenSymbol = "SolvBTC.ENA";
  const wrappedSft = "0xB816018E5d421E8b809A4dc01aF179D86056eBDF";
  const wrappedSlot = "";
  const navOracle = "0x9C491539AeC346AAFeb0bee9a1e9D9c02AB50889";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['solvBTC.ENA_bnb']