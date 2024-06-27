const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Ethena";
  const tokenName = "SolvBTC Ethena";
  const tokenSymbol = "SolvBTC.ENA";
  const wrappedSft = "0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe";
  const wrappedSlot =
    "38110458806523432052630209861008760559065076965924218691659245408576790171249";
  const navOracle = "0x540a9DBBA1AE6250253ba8793714492ee357ac1D";

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

module.exports.tags = ["solvBTC.ENA_merlin"];
