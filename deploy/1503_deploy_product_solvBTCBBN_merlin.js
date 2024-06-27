const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Babylon";
  const tokenName = "SolvBTC Babylon";
  const tokenSymbol = "SolvBTC.BBN";
  const wrappedSft = "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae";
  const wrappedSlot =
    "23002376000286537971644610945217253049745413385836602646876543302447601012196";
  const navOracle = "0x540a9dbba1ae6250253ba8793714492ee357ac1d";

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

module.exports.tags = ["solvBTC.BBN_merlin"];
