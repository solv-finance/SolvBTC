const colors = require("colors");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const version = "_v2.0";

  const deterministicSuffix = {
    dev_sepolia: "_dev" + version,
    sepolia: "_tnt" + version,
    bsctest: "_tnt" + version,
    avax_test: "_tnt" + version,
    merlin_test: "_tnt" + version,
    blast_test: "_tnt" + version,
    ailayer_test: "_tnt" + version,
    bob_test: "_tnt" + version,
    core_test: "_tnt" + version,
    base_test: "_tnt" + version,
    taiko_test: "_tnt" + version,
    hashkey_test: "_tnt" + version,
    bera_test: "_tnt" + version,
    linea_test: "_tnt" + version,

    mainnet: version,
    arb: version,
    bsc: version,
    merlin: version,
    mantle: version,
    ailayer: version,
    bob: version,
    avax: version,
    base: version,
    core: version,
    taiko: version,
    mode: version,
    linea: version,
    bitlayer: version,
    corn: version,
  };

  const instance = await deploy("SolvBTCYieldToken" + version, {
    contract: "SolvBTCYieldToken",
    from: deployer,
    log: true,
    deterministicDeployment: ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(
        "SolvBTCYieldToken" + deterministicSuffix[network.name]
      )
    ),
  });
  console.log(
    `* INFO: ${colors.yellow(
      `SolvBTCYieldTokenImpl`
    )} deployed at ${colors.green(instance.address)} on ${colors.red(
      network.name
    )}`
  );
};

module.exports.tags = ["SolvBTCYTImpl"];
