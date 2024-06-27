const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Babylon";
  const tokenName = "SolvBTC Babylon";
  const tokenSymbol = "SolvBTC.BBN";
  const wrappedSft = "0xb816018e5d421e8b809a4dc01af179d86056ebdf";
  const wrappedSlot =
    "1336354853777768727075850191656536701909968430898108410559797247549735288643";
  const navOracle = "0x9C491539AeC346AAFeb0bee9a1e9D9c02AB50889";

  await factoryHelpers.deployProxy(
    productType,
    productName,
    tokenName,
    tokenSymbol,
    wrappedSft,
    wrappedSlot,
    navOracle
  );
};

module.exports.tags = ["solvBTC.BBN_bnb"];
