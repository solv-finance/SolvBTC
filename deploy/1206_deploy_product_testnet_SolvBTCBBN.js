const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  // https://fm-testnet.solv.finance/open-fund/management/78/overview
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Yield Pool (BBN)";
  const tokenName = "SolvBTC Yield Pool (BBN)";
  const tokenSymbol = "SolvBTC.BBN";
  const wrappedSft = "0xb85a099103de07ac3d2c498453a6599d273be701";
  const wrappedSlot = "21525797116469342010147555198495458332450504371225068883909641098487130211639";
  const navOracle = "0x2271d9fb0a45b63c781d038d0f44596e865dbc2b";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['SolvBTC.BBN-testnet']