const factoryHelpers = require("./helpers/factoryHelpers");

module.exports = async ({ deployments }) => {
  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "Solv BTC";
  const tokenName = "Solv BTC";
  const tokenSymbol = "SolvBTC";
  const wrappedSft = "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce";
  const wrappedSlot =
    "71875420614193724644548223076121034603956938221596243170032844961259965130427";
  const navOracle = "0x412b49a7dc7318d856c73e3348d9692e25fed437";

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

module.exports.tags = ["solvBTC_mantle"];
