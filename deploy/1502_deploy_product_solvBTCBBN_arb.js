const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Babylon";
  const tokenName = "SolvBTC Babylon";
  const tokenSymbol = "SolvBTC.BBN";
  const wrappedSft = "0x22799daa45209338b7f938edf251bdfd1e6dcb32";
  const wrappedSlot =
    "25315353894199778801354907614668596034124918468786689102544470186607665630642";
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

module.exports.tags = ["solvBTC.BBN_arb"];
