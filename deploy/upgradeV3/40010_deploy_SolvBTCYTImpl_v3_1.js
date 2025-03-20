const colors = require("colors");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const version = "_v3.1";

  const deterministicSuffixes = {
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
    bera_test: "_tnt" + version,
    bera_cArtio: "_tnt" + version,
    linea_test: "_tnt" + version,
    bitlayer_test: "_tnt" + version,
    rootstock_test: "_tnt" + version,
    corn_test: "_tnt" + version,
  };

  const deterministicSuffix = deterministicSuffixes[network.name] || version;

  const instance = await deploy("SolvBTCYieldToken" + version, {
    contract: "SolvBTCYieldTokenV3_1",
    from: deployer,
    log: true,
    deterministicDeployment: ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("SolvBTCYieldToken" + deterministicSuffix)
    ),
  });
  console.log(
    `* INFO: ${colors.yellow(
      `SolvBTCYieldTokenImpl_V3`
    )} deployed at ${colors.green(instance.address)} on ${colors.red(
      network.name
    )}`
  );
};

module.exports.tags = ["SolvBTCYTImpl_V3_1"];
