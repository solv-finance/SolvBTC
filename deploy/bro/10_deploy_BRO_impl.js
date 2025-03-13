const colors = require("colors");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const version = "_v1.0";

  const deterministicSuffixes = {
    dev_sepolia: "_devs" + version,
    sepolia: "_tnt" + version,
  };

  const deterministicSuffix = deterministicSuffixes[network.name] || version;

  const instance = await deploy("BROImpl" + version, {
    contract: "BitcoinReserveOffering",
    from: deployer,
    log: true,
    deterministicDeployment: ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("BRO" + deterministicSuffix)
    ),
  });
  console.log(
    `* INFO: ${colors.yellow(`BROImpl`)} deployed at ${colors.green(
      instance.address
    )} on ${colors.red(network.name)}`
  );
};

module.exports.tags = ["BRO_impl"];
