const assert = require('assert');
const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SftWrappedTokenFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const sftWrappedTokenFactoryAddress = (await deployments.get('SftWrappedTokenFactory')).address;
  const sftWrappedTokenFactory = SftWrappedTokenFactoryFactory.attach(sftWrappedTokenFactoryAddress);

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCYieldTokenFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const oldProductType = 'SolvBTC Yield Pool';
  const newProductType = 'SolvBTC Yield Token';

  const solvBTCYieldTokenBeaconInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenBeaconAddresses;
  const solvBTCYieldTokenInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const beaconAddress = await sftWrappedTokenFactory.getBeacon(oldProductType);
  assert(beaconAddress == solvBTCYieldTokenBeaconInfos[network.name], `${network.name} beacon address not matched`);
  const importBeaconTx = await solvBTCYieldTokenFactory.importBeacon(newProductType, beaconAddress);
  console.log(`* INFO: Import SolvBTCYieldToken beacon to SolvBTCYieldTokenFactory at ${importBeaconTx.hash}`);
  await txWait(importBeaconTx);

  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let erc20Address = await sftWrappedTokenFactory.getProxy(oldProductType, productName);
    assert(erc20Address == solvBTCYieldTokenInfos[network.name].erc20, `${network.name} ${productName} token address not matched`);
    let importProxyTx = await solvBTCYieldTokenFactory.importProductProxy(newProductType, productName, erc20Address);
    console.log(`* INFO: Import ${productName} to SolvBTCYieldTokenFactory at ${importProxyTx.hash}`);
    await txWait(importProxyTx);
  }
};

module.exports.tags = ['ImportSolvBTCYTToFactory']
