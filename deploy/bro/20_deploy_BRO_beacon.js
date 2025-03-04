const UpgradeableBeacon = require('@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts-v5/proxy/beacon/UpgradeableBeacon.sol/UpgradeableBeacon.json');
const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const implAddress = (await deployments.get('BROImpl_v1.0')).address;

  const instance = await deploy('BROBeacon', {
    contract: UpgradeableBeacon,
    from: deployer,
    log: true,
    args: [ implAddress, deployer ],
    deterministicDeployment: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("BROBeacon"))
  });
  console.log(`* INFO: ${colors.yellow(`BROBeacon`)} deployed at ${colors.green(instance.address)} on ${colors.red(network.name)}`);

};

module.exports.tags = ['BRO_beacon']
