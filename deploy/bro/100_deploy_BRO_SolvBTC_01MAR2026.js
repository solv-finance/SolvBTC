const BeaconProxy = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts-v5/proxy/beacon/BeaconProxy.sol/BeaconProxy.json');
const colors = require('colors');
const { ethers } = require('hardhat');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const broInfos = {
    dev_sepolia: {
      name: "BRO SolvBTC 01MAR2026",
      symbol: "BRO-SolvBTC-01MAR2026",
      wrappedSft: "0x1bdA9d2d280054C5CF657B538751dD3bB88671e3",
      wrappedSlot: "77490893808118283831741446642904681173330829094617591694418336651036418175900",
      exchangeRate: ethers.utils.parseEther("1.05"),
      solvBTCAddress: "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6",
    }
  }

  const beaconAddress = (await deployments.get('BROBeacon')).address;

  const broInfo = broInfos[network.name];
  const broMock = (await ethers.getContractFactory('BitcoinReserveOffering')).attach(ethers.constants.AddressZero);
  const initData = await broMock.populateTransaction.initialize(
    broInfo.name, broInfo.symbol, broInfo.wrappedSft, broInfo.wrappedSlot, 
    broInfo.exchangeRate, broInfo.solvBTCAddress
  );

  const instance = await deploy('BRO-SolvBTC-01MAR2026', {
    contract: BeaconProxy,
    from: deployer,
    log: true,
    args: [ beaconAddress, initData.data ],
    deterministicDeployment: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BRO-SolvBTC-01MAR2026-devs"))
  });
  console.log(`* INFO: ${colors.yellow(`BRO-SolvBTC-01MAR2026`)} deployed at ${colors.green(instance.address)} on ${colors.red(network.name)}`);

};

module.exports.tags = ['BRO-SolvBTC-01MAR2026']
