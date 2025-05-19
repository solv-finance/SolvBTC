const BeaconProxy = require("@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts-v5/proxy/beacon/BeaconProxy.sol/BeaconProxy.json");
const colors = require("colors");
const { ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const broInfos = {
    mainnet: {
      name: "BRO SOLV 20MAY2026",
      symbol: "BRO-SOLV-20MAY2026",
      wrappedSft: "0x982d50f8557d57b748733a3fc3d55aef40c46756",
      wrappedSlot:
        "59941817680784839512955531781142811538110068167415369884908527049217128305967",
      exchangeRate: ethers.utils.parseEther("4352256.45"),
      solvBTCAddress: "0x7A56E1C57C7475CCf742a1832B028F0456652F97",
    },
  };

  const beaconAddress = (await deployments.get("BROBeacon")).address;

  const broInfo = broInfos[network.name];
  const broMock = (
    await ethers.getContractFactory("BitcoinReserveOffering")
  ).attach(ethers.constants.AddressZero);
  const initData = await broMock.populateTransaction.initialize(
    broInfo.name,
    broInfo.symbol,
    broInfo.wrappedSft,
    broInfo.wrappedSlot,
    broInfo.exchangeRate,
    broInfo.solvBTCAddress
  );

  const instance = await deploy("BRO-SOLV-20MAY2026", {
    contract: BeaconProxy,
    from: deployer,
    log: true,
    args: [beaconAddress, initData.data],
    deterministicDeployment: ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("BRO-SOLV-20MAY2026")
    ),
  });
  console.log(
    `* INFO: ${colors.yellow(`BRO-SOLV-20MAY2026`)} deployed at ${colors.green(
      instance.address
    )} on ${colors.red(network.name)}`
  );
};

module.exports.tags = ["BRO-SOLV-20MAY2026"];
