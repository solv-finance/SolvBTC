module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const TokenFactory = await ethers.getContractFactory("SolvBTC", deployer);
  const tokenAddresses = {
    dev_sepolia: [
      '0xe8C3edB09D1d155292BE0453d57bC3250a0084B6',  // solvBTC
      '0x32Ea1777bC01977a91D15a1C540cbF29bE17D89D',  // xSolvBTC 
    ],
  };

  const xSolvBTCPoolAddress = (await deployments.get("XSolvBTCPoolProxy")).address;

  for (let tokenAddress of tokenAddresses[network.name]) {
    const token = TokenFactory.attach(tokenAddress);

    // grant minter role to xSolvBTCPool
    const minterRole = await token.SOLVBTC_MINTER_ROLE();
    const hasMinterRole = await token.hasRole(minterRole, xSolvBTCPoolAddress);
    if (hasMinterRole) {
      console.log(`Token ${tokenAddress} already granted minter role to xSolvBTCPool`);
    } else {
      const grantMinterTx = await token.grantRole(minterRole, xSolvBTCPoolAddress);
      console.log(`Token ${tokenAddress} grant minter role to xSolvBTCPool at tx: ${grantMinterTx.hash}`);
      await grantMinterTx.wait(1);
    }

    // grant burner role to xSolvBTCPool
    const burnerRole = await token.SOLVBTC_POOL_BURNER_ROLE();
    const hasBurnerRole = await token.hasRole(burnerRole, xSolvBTCPoolAddress);
    if (hasBurnerRole) {
      console.log(`Token ${tokenAddress} already granted burner role to xSolvBTCPool`);
    } else {
      const grantBurnerTx = await token.grantRole(burnerRole, xSolvBTCPoolAddress);
      console.log(`Token ${tokenAddress} grant burner role to xSolvBTCPool at tx: ${grantBurnerTx.hash}`);
      await grantBurnerTx.wait(1);
    }
  }

};

module.exports.tags = ['GrantRoleToXSolvBTCPool']
