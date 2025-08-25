const colors = require("colors");
const { constants } = require("ethers");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const proposers = {
    dev_sepolia: [deployer, "0x195a4b5A35D0729394D5603deB9AAb941eC1e7ec"],
    bob: ["0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D"],
  };

  const executors = {
    dev_sepolia: [deployer, "0x195a4b5A35D0729394D5603deB9AAb941eC1e7ec"],
    bob: ["0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D"],
  };

  const minDelay = {
    dev_sepolia: 3600,
    bob: 3 * 24 * 60 * 60,
  };

  const defaultMinDelay = 7 * 24 * 60 * 60;

  const instance = await deploy("SolvTimelock", {
    contract: "SolvTimelock",
    from: deployer,
    log: true,
    args: [
      minDelay[network.name] || defaultMinDelay,
      proposers[network.name] || [deployer],
      executors[network.name] || [deployer],
      constants.AddressZero,
    ],
  });
  console.log(
    `* INFO: ${colors.yellow(`SolvTimelock`)} deployed at ${colors.green(
      instance.address
    )} on ${colors.red(network.name)}`
  );
};

module.exports.tags = ["SolvTimelock"];
