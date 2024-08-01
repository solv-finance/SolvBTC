const factoryHelpers = require('../helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  // https://fm-testnet.solv.finance/open-fund/management/73/overview
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Yield Pool";
  const tokenName = "SolvBTC Yield Pool";
  const tokenSymbol = "SolvBTC.YP";
  const wrappedSft = "0xb85a099103de07ac3d2c498453a6599d273be701";
  const wrappedSlot = "40157405216900912931362747879010359972656634598029865920249696500324936062978";
  const navOracle = "0x2271d9fb0a45b63c781d038d0f44596e865dbc2b";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['SolvBTC.YP-testnet']