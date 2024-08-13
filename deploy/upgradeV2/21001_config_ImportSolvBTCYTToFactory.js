const assert = require('assert');
const colors = require('colors');
const { txWait } = require('../utils/deployUtils');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SftWrappedTokenFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const sftWrappedTokenFactoryAddress = (await deployments.get('SftWrappedTokenFactory')).address;
  const sftWrappedTokenFactory = SftWrappedTokenFactoryFactory.attach(sftWrappedTokenFactoryAddress);

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory('SolvBTCFactory', deployer);
  const solvBTCYieldTokenFactoryAddress = (await deployments.get('SolvBTCYieldTokenFactory')).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(solvBTCYieldTokenFactoryAddress);

  const oldProductType = 'SolvBTC Yield Pool';
  const newProductType = 'SolvBTC Yield Token';

  const solvBTCYieldTokenBeaconInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenBeaconAddresses;
  const solvBTCYieldTokenInfos = require('../SolvBTCYieldToken/20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  let beaconInFactory = await solvBTCYieldTokenFactory.getBeacon(newProductType);
  if (beaconInFactory == ethers.constants.AddressZero) {
    const beaconAddress = await sftWrappedTokenFactory.getBeacon(oldProductType);
    assert(beaconAddress == solvBTCYieldTokenBeaconInfos[network.name], `${network.name} beacon address not matched`);
    const importBeaconTx = await solvBTCYieldTokenFactory.importBeacon(newProductType, beaconAddress);
    console.log(`* INFO: Import SolvBTCYieldToken beacon to SolvBTCYieldTokenFactory at ${importBeaconTx.hash}`);
    await txWait(importBeaconTx);
  } else {
    console.log(`* INFO: SolvBTCYieldToken beacon already imported`);
  }
  beaconInFactory = await solvBTCYieldTokenFactory.getBeacon(newProductType);
  console.log(`* INFO: SolvBTCYieldToken beacon in SolvBTCYieldTokenFactory is ${beaconInFactory}`);


  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let proxyInFactory = await solvBTCYieldTokenFactory.getProxy(newProductType, productName);
    if (proxyInFactory == ethers.constants.AddressZero) {
      let erc20Address = await sftWrappedTokenFactory.getProxy(oldProductType, productName);
      assert(erc20Address == solvBTCYieldTokenInfos[network.name][productName].erc20, `${network.name} ${productName} token address not matched`);
      let importProxyTx = await solvBTCYieldTokenFactory.importProductProxy(newProductType, productName, erc20Address);
      console.log(`* INFO: Import ${productName} to SolvBTCYieldTokenFactory at ${importProxyTx.hash}`);
      await txWait(importProxyTx);
    } else {
      console.log(`* INFO: ${productName} proxy already imported`);
    }
  }
};

module.exports.tags = ['ImportSolvBTCYTToFactory']
