const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "SolvBTC Yield Pool";
  const productName = "SolvBTC Babylon";
  const tokenName = "SolvBTC Babylon";
  const tokenSymbol = "SolvBTC.BBN";
  const wrappedSft = "0x982d50f8557d57b748733a3fc3d55aef40c46756";
  const wrappedSlot =
    "83660682397659272392863020907646506973985956658124321060921311208510599625298";
  const navOracle = "0x8c29858319614380024093dbee553f9337665756";

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

module.exports.tags = ["solvBTC.BBN_eth"];
