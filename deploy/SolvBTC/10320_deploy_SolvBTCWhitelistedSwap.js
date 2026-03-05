const transparentUpgrade = require("../utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const initParams = {
    sepolia: {
        governor: deployer,
        pauseAdmin: deployer,
        solvbtc: "0xE33109766662932a26d978123383ff9E7bdeF346",
        currency: "0x7A9689202fddE4C2091B480c70513184b2F8555C",  // WBTC
        currencyVault: "0xf54ae9d68c986b39690da73f89b78e8c9ea4683f",
        feeRecipient: deployer,
        feeRate: 100,
        isWhitelistEnabled: true,
    },
    mainnet: {
        governor: "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D",
        pauseAdmin: "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D",
        solvbtc: "0x7A56E1C57C7475CCf742a1832B028F0456652F97",
        currency: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",  // cbBTC
        currencyVault: "0xad713bd85e8bff9ce85ca03a8a930e4a38f6893d",
        feeRecipient: "0x5ef01B1eFfA34Bdd3A305a968A907108D52FF234",
        feeRate: 5,
        isWhitelistEnabled: true,
    },
    bsc: {
        governor: "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D",
        pauseAdmin: "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D",
        solvbtc: "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7",
        currency: "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c",  // BTCB
        currencyVault: "0x9537bc0546506785bd1ebd19fd67d1f06800d185",
        feeRecipient: "0x5ef01B1eFfA34Bdd3A305a968A907108D52FF234",
        feeRate: 5,
        isWhitelistEnabled: true,
    }
  }

  const contractName = "SolvBTCWhitelistedSwap";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {};
  const upgrades = versions[network.name]?.map((v) => { return firstImplName + "_" + v; }) || [];

  await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
      log: true,
    },
    {
      initializer: {
        method: "initialize",
        args: [
          initParams[network.name].governor,
          initParams[network.name].pauseAdmin,
          initParams[network.name].solvbtc,
          initParams[network.name].currency,
          initParams[network.name].currencyVault,
          initParams[network.name].feeRecipient,
          initParams[network.name].feeRate,
          initParams[network.name].isWhitelistEnabled,
        ],
      },
      upgrades: upgrades,
    }
  );
};

module.exports.tags = ["SolvBTCWhitelistedSwap"];
