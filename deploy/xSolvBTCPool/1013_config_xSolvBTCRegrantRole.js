module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const xSolvBTCMultiAssetPoolAddress = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;
  const xSolvBTCPoolAddress = (await deployments.get("XSolvBTCPoolProxy")).address;

  const xSolvBTCFactory = await ethers.getContractFactory("SolvBTCYieldTokenV3_1", deployer);
  const xSolvBTCAddress = require('./1099_export_xSolvBTCPoolInfos').XSolvBTCInfos[network.name].token;
  const token = xSolvBTCFactory.attach(xSolvBTCAddress);

  const minterRole = await token.SOLVBTC_MINTER_ROLE();
  const burnerRole = await token.SOLVBTC_POOL_BURNER_ROLE();

  // revoke minter role from old multiAssetPool
  const oldPoolHasMinterRole = await token.hasRole(minterRole, xSolvBTCMultiAssetPoolAddress);
  if (oldPoolHasMinterRole) {
    const revokeMinterTx = await token.revokeRole(minterRole, xSolvBTCMultiAssetPoolAddress);
    console.log(`Token ${xSolvBTCAddress} revoke minter role from old multiAssetPool at tx: ${revokeMinterTx.hash}`);
    await revokeMinterTx.wait(1);
  }

  // revoke burner role from old multiAssetPool
  const oldPoolHasBurnerRole = await token.hasRole(burnerRole, xSolvBTCMultiAssetPoolAddress);
  if (oldPoolHasBurnerRole) {
    const revokeBurnerTx = await token.revokeRole(burnerRole, xSolvBTCMultiAssetPoolAddress);
    console.log(`Token ${xSolvBTCAddress} revoke burner role from old multiAssetPool at tx: ${revokeBurnerTx.hash}`);
    await revokeBurnerTx.wait(1);
  }

  // grant minter role to xSolvBTCPool
  const newPoolHasMinterRole = await token.hasRole(minterRole, xSolvBTCPoolAddress);
  if (newPoolHasMinterRole) {
    console.log(`Token ${xSolvBTCAddress} already granted minter role to xSolvBTCPool`);
  } else {
    const grantMinterTx = await token.grantRole(minterRole, xSolvBTCPoolAddress);
    console.log(`Token ${xSolvBTCAddress} grant minter role to xSolvBTCPool at tx: ${grantMinterTx.hash}`);
    await grantMinterTx.wait(1);
  }

  // grant burner role to xSolvBTCPool
  const newPoolHasBurnerRole = await token.hasRole(burnerRole, xSolvBTCPoolAddress);
  if (newPoolHasBurnerRole) {
    console.log(`Token ${xSolvBTCAddress} already granted burner role to xSolvBTCPool`);
  } else {
    const grantBurnerTx = await token.grantRole(burnerRole, xSolvBTCPoolAddress);
    console.log(`Token ${xSolvBTCAddress} grant burner role to xSolvBTCPool at tx: ${grantBurnerTx.hash}`);
    await grantBurnerTx.wait(1);
  }
};

module.exports.tags = ['xSolvBTCRegrantRole']
