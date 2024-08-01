const assert = require('assert');
const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SftWrappedTokenFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const sftWrappedTokenFactoryAddress = (await deployments.get('SftWrappedTokenFactory')).address;
  const sftWrappedTokenFactory = SftWrappedTokenFactoryFactory.attach(sftWrappedTokenFactoryAddress);

  const SolvBTCFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCFactoryAddress = (await deployments.get('SolvBTCFactory')).address;
  const solvBTCFactory = SolvBTCFactoryFactory.attach(solvBTCFactoryAddress);

  const oldProductType = 'Open-end Fund Share Wrapped Token';
  const oldProductName = 'Solv BTC';
  const newProductType = 'Solv BTC';
  const newProductName = 'Solv BTC';

  const solvBTCBeaconInfos = require('../SolvBTC/10999_export_SolvBTCInfos').SolvBTCBeaconAddresses;
  const solvBTCInfos = require('../SolvBTC/10999_export_SolvBTCInfos').SolvBTCInfos;

  const beaconAddress = await sftWrappedTokenFactory.getBeacon(oldProductType);
  assert(beaconAddress == solvBTCBeaconInfos[network.name]);
  const importBeaconTx = await solvBTCFactory.importBeacon(newProductType, beaconAddress);
  console.log(`* INFO: Import SolvBTC beacon to SolvBTCFactory at ${importBeaconTx.hash}`);
  await txWait(importBeaconTx);

  const solvBTCAddress = await sftWrappedTokenFactory.getProxy(oldProductType, oldProductName);
  assert(solvBTCAddress == solvBTCInfos[network.name].erc20);
  const importProxyTx = await solvBTCFactory.importProductProxy(newProductType, newProductName, solvBTCAddress);
  console.log(`* INFO: Import SolvBTC proxy to SolvBTCFactory at ${importProxyTx.hash}`);
  await txWait(importProxyTx);
};

module.exports.tags = ['ImportSolvBTCToFactory']
