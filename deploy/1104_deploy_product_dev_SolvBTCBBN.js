const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  // https://fm-dev-0ak6s1klbcud.solv.finance/open-fund/management/166/overview
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Yield Pool (BBN)";
  const tokenName = "SolvBTC Yield Pool (BBN)";
  const tokenSymbol = "SolvBTC.BBN";
  const wrappedSft = "0x1bda9d2d280054c5cf657b538751dd3bb88671e3";
  const wrappedSlot = "109960959664229641296182064182695512546041565238657772188637862410825890720389";
  const navOracle = "0x6255a8d0485659e7f45d97c3d61e532b3fb01877";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['SolvBTC.BBN-dev']