const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Ethena";
  const tokenName = "SolvBTC Ethena";
  const tokenSymbol = "SolvBTC.ENA";
  const wrappedSft = "0x22799DAA45209338B7f938edf251bdfD1E6dCB32";
  const wrappedSlot =
    "73370673862338774703804051393194258049657950181644297527289682663167654669645";
  const navOracle = "0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD";

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

module.exports.tags = ["solvBTC.ENA_arb"];
