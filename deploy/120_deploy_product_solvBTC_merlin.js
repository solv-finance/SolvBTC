const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "solvBTC";
  const wrappedSft = "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce";
  const wrappedSlot = "7685891756137981582934663773270438191467779655160310556659968321974138778374";
  const navOracle = "0xf5a247157656678398b08d3efa1673358c611a3f";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['solvBTC_bnb']