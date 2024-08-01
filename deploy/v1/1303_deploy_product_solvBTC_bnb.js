const factoryHelpers = require('../helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0x744697899058b32d84506ad05dc1f3266603ab8a";
  const wrappedSlot = "77587025559498258415588945116212333974103493585554356315875771683147378204475";
  const navOracle = "0xbfda88765a07f60b04619d1c95a3ec1e75f8b71e";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['solvBTC_bnb']