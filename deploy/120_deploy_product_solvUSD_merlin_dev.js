const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv USD";
  const tokenName = "Solv USD";
  const tokenSymbol = "solvUSD";
  const wrappedSft = "0xb85a099103de07ac3d2c498453a6599d273be701";
  const wrappedSlot = "67445315312322480753555525364853463232870784840200792837294494035006934636059";
  const navOracle = "0xBA9544B14fA4CA5F2543EA28F368BfDAe9885Ba7";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['merlinDevSolvUSD']