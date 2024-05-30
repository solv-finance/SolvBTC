const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv Strategy USD";
  const tokenName = "Solv Strategy USD";
  const tokenSymbol = "stUSD";
  const wrappedSft = "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae";
  const wrappedSlot = "48541436984192663650063229695481937992236063285084352719742927842862739825849";
  const navOracle = "0x540a9DBBA1AE6250253ba8793714492ee357ac1D";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['stUSD']