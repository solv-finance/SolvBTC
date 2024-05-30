const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  // https://fm-dev-0ak6s1klbcud.solv.finance/open-fund/management/163/overview
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Yield Pool";
  const tokenName = "SolvBTC Yield Pool";
  const tokenSymbol = "SolvBTC.YP";
  const wrappedSft = "0x1bda9d2d280054c5cf657b538751dd3bb88671e3";
  const wrappedSlot = "55816906216140072643656852625631805111843385002459235182041733401755343339377";
  const navOracle = "0x6255a8d0485659e7f45d97c3d61e532b3fb01877";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['SolvBTC.YP-dev']