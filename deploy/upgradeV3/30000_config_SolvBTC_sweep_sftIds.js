const colors = require("colors");
const { BigNumber } = require("ethers");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const shareAddresses = {
    dev_sepolia: "0x1bdA9d2d280054C5CF657B538751dD3bB88671e3",
    sepolia: "0xB85A099103De07AC3d2C498453a6599D273be701",
    bsctest: "0xB85A099103De07AC3d2C498453a6599D273be701",
    
  };

  const SolvBTCFactoryFactory = await ethers.getContractFactory("SolvBTCFactory", deployer);
  const solvBTCFactoryAddress = (await deployments.get("SolvBTCFactory")).address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const solvBTCAddress = await solvBTCFactory.getProxy("Solv BTC", "Solv BTC");
  const SolvBTCFactory = await ethers.getContractFactory("SolvBTC", deployer);
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);
  console.log(`* INFO: SolvBTC at ${colors.yellow(solvBTCAddress)}`);

  let holdingSftAmount = await ethers.provider.getStorageAt(solvBTCAddress, 4);
  holdingSftAmount = BigNumber.from(holdingSftAmount).toNumber();
  console.log(`* INFO: holdingSftAmount: ${holdingSftAmount}`);

  while (holdingSftAmount > 0) {
    let sweepTx = await solvBTC.sweepEmptySftIds(shareAddresses[network.name], 500);
    console.log(`* INFO: sweepEmptySftIds at ${sweepTx.hash}`);
    await sweepTx.wait(1);

    holdingSftAmount = await ethers.provider.getStorageAt(solvBTCAddress, 4);
    holdingSftAmount = BigNumber.from(holdingSftAmount).toNumber();
    console.log(`* INFO: holdingSftAmount: ${BigNumber.from(holdingSftAmount).toNumber()}`);
  }
};

module.exports.tags = ["SolvBTC_SweepSftIds"];
