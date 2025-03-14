const assert = require("assert");
const colors = require("colors");
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryV2Factory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCYieldTokenFactoryV2Address = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactoryV2 = SolvBTCYieldTokenFactoryV2Factory.attach(solvBTCYieldTokenFactoryV2Address);

  const SolvBTCYieldTokenFactoryV3Factory = await ethers.getContractFactory('SolvBTCFactoryV3', deployer);
  const solvBTCYieldTokenFactoryV3Address = (await deployments.get('SolvBTCYieldTokenFactoryV3')).address;
  const solvBTCYieldTokenFactoryV3 = SolvBTCYieldTokenFactoryV3Factory.attach(solvBTCYieldTokenFactoryV3Address);

  const productType = 'SolvBTC Yield Token';

  const beaconAddress = await solvBTCYieldTokenFactoryV2.getBeacon(productType);
  let beaconAddressInFactoryV3 = await solvBTCYieldTokenFactoryV3.getBeacon(productType);

  if (beaconAddressInFactoryV3 != beaconAddress) {
    const importTx = await solvBTCYieldTokenFactoryV3.importBeacon(productType, beaconAddress);
    console.log(`* INFO: Import beacon ${beaconAddress} at ${importTx.hash}`);
    await txWait(importTx);
  }

  beaconAddressInFactoryV3 = await solvBTCYieldTokenFactoryV3.getBeacon(productType);
  assert(beaconAddressInFactoryV3 == beaconAddress, `Invalid beacon address ${beaconAddressInFactoryV3}`);
  console.log(`* INFO: Beacon imported at ${colors.yellow(beaconAddressInFactoryV3)}`);

  const transferBeaconOwnershipTx = await solvBTCYieldTokenFactoryV2.transferBeaconOwnership(productType, solvBTCYieldTokenFactoryV3Address);
  console.log(`* INFO: Transfer beacon ownership to SolvBTCFactoryV3 at ${transferBeaconOwnershipTx.hash}`);
  await txWait(transferBeaconOwnershipTx);
};

module.exports.tags = ["SolvBTCYTFactoryV3_ImportBeacon"];
