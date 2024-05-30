const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  // https://fm-dev-0ak6s1klbcud.solv.finance/open-fund/management/154/overview
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0x1bda9d2d280054c5cf657b538751dd3bb88671e3";
  const wrappedSlot = "16245748164256642266613440095062032814331096931003133187862105072391943914996";
  const navOracle = "0x94aa8848de25eec17c68b01b3d5ecad07709498c";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['SolvBTC-dev']