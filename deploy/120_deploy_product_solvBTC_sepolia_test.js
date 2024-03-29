const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "solvBTC";
  const wrappedSft = "0xb85a099103de07ac3d2c498453a6599d273be701";
  const wrappedSlot = "50913167548085450266615759389672821141079304680410788120987795074884160700249";
  const navOracle = "0x2271d9fb0a45b63c781d038d0f44596e865dbc2b";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['sepoliaTestSolvBTC']