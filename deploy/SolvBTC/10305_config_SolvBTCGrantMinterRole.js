const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactory = await ethers.getContractFactory('SolvBTCV3', deployer);
  const solvBTCAddress = require('./10399_export_SolvBTCInfos').SolvBTCInfos[network.name].erc20;
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);

  const solvBTCMultiAssetPoolAddress = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;
  const solvBTCMultiAssetPoolAddressInConfig = require('./10099_export_SolvBTCInfos').SolvBTCMultiAssetPoolAddresses[network.name];
  assert(solvBTCMultiAssetPoolAddress == solvBTCMultiAssetPoolAddressInConfig, 'pool address not matched');

  const minterRole = await solvBTC.SOLVBTC_MINTER_ROLE();
  const hasMinterRole = await solvBTC.hasRole(minterRole, solvBTCMultiAssetPoolAddress);
  if (!hasMinterRole) {
    const grantMinterRoleTx = await solvBTC.grantRole(minterRole, solvBTCMultiAssetPoolAddress);
    console.log(`* INFO: SolvBTC grant minter role to MultiAssetPool ${solvBTCMultiAssetPoolAddress} at ${grantMinterRoleTx.hash}`);
    await txWait(grantMinterRoleTx);
  } else {
    console.log(`* INFO: SolvBTC already granted minter role to MultiAssetPool ${solvBTCMultiAssetPoolAddress}`);
  }

  const poolBurnerRole = await solvBTC.SOLVBTC_POOL_BURNER_ROLE();
  const hasBurnerRole = await solvBTC.hasRole(poolBurnerRole, solvBTCMultiAssetPoolAddress);
  if (!hasBurnerRole) {
    const grantBurnerRoleTx = await solvBTC.grantRole(poolBurnerRole, solvBTCMultiAssetPoolAddress);
    console.log(`* INFO: SolvBTC grant pool burner role to MultiAssetPool ${solvBTCMultiAssetPoolAddress} at ${grantBurnerRoleTx.hash}`);
    await txWait(grantBurnerRoleTx);
  } else {
    console.log(`* INFO: SolvBTC already granted pool burner role to MultiAssetPool ${solvBTCMultiAssetPoolAddress}`);
  }
};

module.exports.tags = ['SolvBTCV3_GrantMinterRole']
