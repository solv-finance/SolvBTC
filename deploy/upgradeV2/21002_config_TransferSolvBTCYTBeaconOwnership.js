const assert = require('assert');
const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SftWrappedTokenFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const sftWrappedTokenFactoryAddress = (await deployments.get('SftWrappedTokenFactory')).address;
  const sftWrappedTokenFactory = SftWrappedTokenFactoryFactory.attach(sftWrappedTokenFactoryAddress);

  const oldProductType = 'SolvBTC Yield Pool';

  const solvBTCFactoryAddresses = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCFactoryAddresses;

  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  assert(solvBTCYieldTokenFactoryAddress == solvBTCFactoryAddresses[network.name]);
  const transferTx = await sftWrappedTokenFactory.transferBeaconOwnership(oldProductType, solvBTCYieldTokenFactoryAddress);
  console.log(`* INFO: Transfer SolvBTCYieldToken beacon ownership to SolvBTCYieldTokenFactory at ${transferTx.hash}`);
  await txWait(transferTx);

};

module.exports.tags = ['TransferSolvBTCYTBeaconOwnership']
