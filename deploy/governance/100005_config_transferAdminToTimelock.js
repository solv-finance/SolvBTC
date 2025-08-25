const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const timelockAddress = (await deployments.get("SolvTimelock")).address;

  const SolvBTCFactoryFactory = await ethers.getContractFactory(
    "SolvBTCFactory",
    deployer
  );
  const solvBTCFactoryAddress = (await deployments.get("SolvBTCFactory"))
    .address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);
  const currentAdmin = await solvBTCFactory.admin();
  const pendingAdmin = await solvBTCFactory.pendingAdmin();
  console.log("currentAdmin ", currentAdmin, "pendingAdmin ", pendingAdmin);
  if (currentAdmin !== timelockAddress && pendingAdmin !== timelockAddress) {
    console.log(
      `* INFO: ${colors.yellow(
        `SolvBTCFactory`
      )} admin ${currentAdmin} is not timelock, transferring to timelock ${timelockAddress}`
    );
    const tx = await solvBTCFactory.transferAdmin(timelockAddress);
    await txWait(tx);
  } else {
    console.log(
      `* INFO: ${colors.yellow(
        `SolvBTCFactory`
      )} admin is already timelock, skipping`
    );
  }
};

module.exports.tags = ["TransferFactoryAdminToTimelock"];
