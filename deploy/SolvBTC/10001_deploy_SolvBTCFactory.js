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
    mode_test: "_tnt" + version,
    form_test: "_tnt" + version,
    bera_test: "_tnt" + version,
    bera_cArtio: "_tnt" + version,
    linea_test: "_tnt" + version,
    bitlayer_test: "_tnt" + version,
    rootstock_test: "_tnt" + version,
    corn_test: "_tnt" + version,

    mainnet: version,
    arb: version,
    bsc: version,
    merlin: version,
    mantle: version,
    ailayer: version,
    bob: version,
    avax: version,
    taiko: version,
    mode: version,
    linea: version,
    bitlayer: version,
    corn: version,
    sonic: version,
    zksync: version,
    sei: version,
    bera: version,
    rootstock: version,
  };

  const admin = deployer;
  const governor = deployer;

  const instance = await deploy("SolvBTCFactory", {
    contract: "SolvBTCFactory",
    from: deployer,
    log: true,
    args: [admin, governor],
    deterministicDeployment: ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(
        "SolvBTCFactory" + deterministicSuffix[network.name]
      )
    ),
  });
  console.log(
    `* INFO: ${colors.yellow(`SolvBTCFactory`)} deployed at ${colors.green(
      instance.address
    )} on ${colors.red(network.name)}`
  );
};

module.exports.tags = ["SolvBTCFactory"];
