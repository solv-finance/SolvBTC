const transparentUpgrade = require("../utils/transparentUpgrade");
const gasTracker = require("../utils/gasTracker");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const gasPrice = await gasTracker.getGasPrice(network.name);

  const tokenName = "Solv USD";
  const tokenSymbol = "SolvUSD";
  const underlyingAsset = "0x769D9b9F057d3600faB76AC9B24eb1dD4416671D";

  const contractName = "SolvBTC";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {};

  const upgrades =
    versions[network.name]?.map((v) => {
      return firstImplName + "_" + v;
    }) || [];

  const { proxy, newImpl, newImplName } =
    await transparentUpgrade.deployOrUpgrade(
      firstImplName,
      proxyName,
      {
        contract: contractName,
        from: deployer,
        gasPrice: gasPrice,
        log: true,
      },
      {
        initializer: {
          method: "initialize",
          args: [tokenName, tokenSymbol, underlyingAsset],
        },
        upgrades: upgrades,
      }
    );
};

module.exports.tags = ["SolvUSD"];
