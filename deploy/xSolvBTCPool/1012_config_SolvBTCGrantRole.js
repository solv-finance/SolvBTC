module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();


  const xSolvBTCPoolAddress = (await deployments.get("XSolvBTCPoolProxy")).address;

  const SolvBTCFactory = await ethers.getContractFactory("SolvBTC", deployer);
  const solvBTCAddress = require('./1099_export_xSolvBTCPoolInfos').SolvBTCAddresses[network.name];
  const token = SolvBTCFactory.attach(solvBTCAddress);
  
  const minterRole = await token.SOLVBTC_MINTER_ROLE();
  const burnerRole = await token.SOLVBTC_POOL_BURNER_ROLE();

  // grant minter role to xSolvBTCPool
  const newPoolHasMinterRole = await token.hasRole(minterRole, xSolvBTCPoolAddress);
  if (newPoolHasMinterRole) {
    console.log(`Token ${solvBTCAddress} already granted minter role to xSolvBTCPool`);
  } else {
    const grantMinterTx = await token.grantRole(minterRole, xSolvBTCPoolAddress);
    console.log(`Token ${solvBTCAddress} grant minter role to xSolvBTCPool at tx: ${grantMinterTx.hash}`);
    await grantMinterTx.wait(1);
  }

  // grant burner role to xSolvBTCPool
  const newPoolHasBurnerRole = await token.hasRole(burnerRole, xSolvBTCPoolAddress);
  if (newPoolHasBurnerRole) {
    console.log(`Token ${solvBTCAddress} already granted burner role to xSolvBTCPool`);
  } else {
    const grantBurnerTx = await token.grantRole(burnerRole, xSolvBTCPoolAddress);
    console.log(`Token ${solvBTCAddress} grant burner role to xSolvBTCPool at tx: ${grantBurnerTx.hash}`);
    await grantBurnerTx.wait(1);
  }

};

module.exports.tags = ['SolvBTCGrantRole']
