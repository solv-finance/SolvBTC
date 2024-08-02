const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const solvBTCYieldTokenMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenMultiAssetPoolAddressInConfig = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenMultiAssetPoolAddresses[network.name];
  assert(solvBTCYieldTokenMultiAssetPoolAddress == solvBTCYieldTokenMultiAssetPoolAddressInConfig, 'pool address not matched');

  const solvBTCYieldTokenInfos = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const SolvBTCYieldTokenFactory = await ethers.getContractFactory('SolvBTCYieldToken', deployer);

  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let erc20Address = solvBTCYieldTokenInfos[network.name][productName].erc20;
    let solvBTCYieldToken = SolvBTCYieldTokenFactory.attach(erc20Address);
    let minterRole = await solvBTCYieldToken.SOLVBTC_MINTER_ROLE();

    let hasRole = await solvBTCYieldToken.hasRole(minterRole, solvBTCYieldTokenMultiAssetPoolAddress);
    if (!hasRole) {
      let grantRoleTx = await solvBTCYieldToken.grantRole(minterRole, solvBTCYieldTokenMultiAssetPoolAddress);
      console.log(`* INFO: ${productName} grant minter role to MultiAssetPool ${solvBTCYieldTokenMultiAssetPoolAddress} at ${grantRoleTx.hash}`);
      await txWait(grantRoleTx);
    } else {
      console.log(`* INFO: ${productName} already granted minter role to MultiAssetPool ${solvBTCYieldTokenMultiAssetPoolAddress}`);
    }
  }
};

module.exports.tags = ['SolvBTCYTGrantMinterRole']
