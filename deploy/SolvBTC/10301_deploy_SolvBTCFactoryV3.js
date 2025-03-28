const colors = require("colors");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const version = "_v3.0";

  const deterministicSuffixes = {
    dev_sepolia: "_dev" + version,
    sepolia: "_tnt" + version,
    bsctest: "_tnt" + version,
  };

  const deterministicSuffix = deterministicSuffixes[network.name] || version;

  const admin = deployer;  // admin address when deploying the contract
  const governor = deployer;
  const safeAdmins = {
    soneium: "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D",
  }

  const instance = await deploy("SolvBTCFactoryV3", {
    contract: "SolvBTCFactoryV3",
    from: deployer,
    log: true,
    args: [admin, governor],
    deterministicDeployment: ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(
        "SolvBTCFactoryV3" + deterministicSuffix
      )
    ),
  });
  console.log(
    `* INFO: ${colors.yellow(`SolvBTCFactoryV3`)} deployed at ${colors.green(
      instance.address
    )} on ${colors.red(network.name)}`
  );

  // transfer admin to safe wallet
  if (safeAdmins[network.name]) {
    const safeAdmin = safeAdmins[network.name];
    const currentAdmin = await solvBTCYieldTokenFactoryV3.admin();
    if (currentAdmin.toLowerCase() != safeAdmin.toLowerCase()) {
      const transferAdminTx = await solvBTCYieldTokenFactoryV3.transferAdmin(safeAdmin);
      console.log(`* INFO: Transfer admin to ${safeAdmin} at ${transferAdminTx.hash}`);
      await transferAdminTx.wait();
    }
  }
};

module.exports.tags = ["SolvBTCFactoryV3"];
