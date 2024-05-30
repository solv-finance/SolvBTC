const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  // https://fm-testnet.solv.finance/open-fund/management/68/overview
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0xb85a099103de07ac3d2c498453a6599d273be701";
  const wrappedSlot = "29645226748952458644023755083107962629798019908597409881398793012721696943353";
  const navOracle = "0x213c2c0f86e7dc4e38ff2eedfcc1a474b0da6147";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['SolvBTC-testnet']