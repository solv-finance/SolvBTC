const colors = require('colors');
const { txWait } = require('../utils/deployUtils');
const assert = require('assert');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCFactory = await ethers.getContractFactory('SolvBTC', deployer);
  const solvBTCAddress = require('./10999_export_SolvBTCInfos').SolvBTCInfos[network.name].erc20;
  const solvBTC = SolvBTCFactory.attach(solvBTCAddress);

  const solvBTCMultiAssetPoolAddress = (await deployments.get('SolvBTCMultiAssetPoolProxy')).address;
  const solvBTCMultiAssetPoolAddressInConfig = require('./10999_export_SolvBTCInfos').SolvBTCMultiAssetPoolAddresses[network.name];
  assert(solvBTCMultiAssetPoolAddress == solvBTCMultiAssetPoolAddressInConfig, 'pool address not matched');

  const minterRole = await solvBTC.SOLVBTC_MINTER_ROLE();
  const hasRole = await solvBTC.hasRole(minterRole, solvBTCMultiAssetPoolAddress);
  if (!hasRole) {
    const grantRoleTx = await solvBTC.grantRole(minterRole, solvBTCMultiAssetPoolAddress);
    console.log(`* INFO: SolvBTC grant minter role to MultiAssetPool ${solvBTCMultiAssetPoolAddress} at ${grantRoleTx.hash}`);
    await txWait(grantRoleTx);
  } else {
    console.log(`* INFO: SolvBTC already granted minter role to MultiAssetPool ${solvBTCMultiAssetPoolAddress}`);
  }

};

module.exports.tags = ['SolvBTCGrantMinterRole']
