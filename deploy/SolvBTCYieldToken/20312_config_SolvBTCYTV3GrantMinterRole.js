const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const solvBTCYieldTokenMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const solvBTCYieldTokenMultiAssetPoolAddressInConfig = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenMultiAssetPoolAddresses[network.name];
  assert(solvBTCYieldTokenMultiAssetPoolAddress == solvBTCYieldTokenMultiAssetPoolAddressInConfig, 'pool address not matched');

  const solvBTCYieldTokenInfos = require('./20999_export_SolvBTCYTInfos').SolvBTCYieldTokenInfos;

  const SolvBTCYieldTokenV3Factory = await ethers.getContractFactory('SolvBTCYieldTokenV3', deployer);

  for (let productName in solvBTCYieldTokenInfos[network.name]) {
    let erc20Address = solvBTCYieldTokenInfos[network.name][productName].erc20;
    let solvBTCYieldToken = SolvBTCYieldTokenV3Factory.attach(erc20Address);
    let minterRole = await solvBTCYieldToken.SOLVBTC_MINTER_ROLE();

    let hasMinterRole = await solvBTCYieldToken.hasRole(minterRole, solvBTCYieldTokenMultiAssetPoolAddress);
    if (!hasMinterRole) {
      let grantMinterRoleTx = await solvBTCYieldToken.grantRole(minterRole, solvBTCYieldTokenMultiAssetPoolAddress);
      console.log(`* INFO: ${productName} grant minter role to MultiAssetPool ${solvBTCYieldTokenMultiAssetPoolAddress} at ${grantMinterRoleTx.hash}`);
      await txWait(grantMinterRoleTx);
    } else {
      console.log(`* INFO: ${productName} already granted minter role to MultiAssetPool ${solvBTCYieldTokenMultiAssetPoolAddress}`);
    }

    let poolBurnerRole = await solvBTCYieldToken.SOLVBTC_POOL_BURNER_ROLE();
    let hasBurnerRole = await solvBTCYieldToken.hasRole(poolBurnerRole, solvBTCYieldTokenMultiAssetPoolAddress);
    if (!hasBurnerRole) {
      let grantBurnerRoleTx = await solvBTCYieldToken.grantRole(poolBurnerRole, solvBTCYieldTokenMultiAssetPoolAddress);
      console.log(`* INFO: ${productName} grant pool burner role to MultiAssetPool ${solvBTCYieldTokenMultiAssetPoolAddress} at ${grantBurnerRoleTx.hash}`);
      await txWait(grantBurnerRoleTx);
    } else {
      console.log(`* INFO: ${productName} already granted pool burner role to MultiAssetPool ${solvBTCYieldTokenMultiAssetPoolAddress}`);
    }
  }
};

module.exports.tags = ['SolvBTCYTV3_GrantMinterRole']
