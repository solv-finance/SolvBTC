const assert = require('assert');
const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SftWrappedTokenFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const sftWrappedTokenFactoryAddress = (await deployments.get('SftWrappedTokenFactory')).address;
  const sftWrappedTokenFactory = SftWrappedTokenFactoryFactory.attach(sftWrappedTokenFactoryAddress);

  const oldProductType = 'Open-end Fund Share Wrapped Token';

  const solvBTCFactoryAddresses = require('../SolvBTC/10999_export_SolvBTCInfos').SolvBTCFactoryAddresses;

  const solvBTCFactoryAddress = (await deployments.get('SolvBTCFactory')).address;
  assert(solvBTCFactoryAddress == solvBTCFactoryAddresses[network.name]);
  const transferTx = await sftWrappedTokenFactory.transferBeaconOwnership(oldProductType, solvBTCFactoryAddress);
  console.log(`* INFO: Transfer SolvBTC beacon ownership to SolvBTCFactory at ${transferTx.hash}`);
  await txWait(transferTx);
};

module.exports.tags = ['TransferSolvBTCBeaconOwnership']
