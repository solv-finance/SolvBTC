module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const xSolvBTCOracleFactory = await ethers.getContractFactory("XSolvBTCOracle", deployer);
  const xSolvBTCOracleAddress = (await deployments.get("XSolvBTCOracleProxy")).address;
  const xSolvBTCOracle = xSolvBTCOracleFactory.attach(xSolvBTCOracleAddress);

  const nav = ethers.utils.parseUnits('1.05', 18);

  const setNavTx = await xSolvBTCOracle.setNav(nav);
  console.log(`Nav set to ${nav} at tx: ${setNavTx.hash}`);
  await setNavTx.wait(1);
};

module.exports.tags = ['OracleSetNav']
