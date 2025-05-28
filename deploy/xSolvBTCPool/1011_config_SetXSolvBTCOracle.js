module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const xSolvBTCFactory = await ethers.getContractFactory("SolvBTCYieldTokenV3_1", deployer);
  const xSolvBTCAddresses = {
    dev_sepolia: '0x32Ea1777bC01977a91D15a1C540cbF29bE17D89D',
  };
  const xSolvBTC = xSolvBTCFactory.attach(xSolvBTCAddresses[network.name]);

  const xSolvBTCOracleAddress = (await deployments.get("XSolvBTCOracleProxy")).address;

  const currentOracle = await xSolvBTC.getOracle();
  if (currentOracle === xSolvBTCOracleAddress) {
    console.log(`xSolvBTCOracle ${xSolvBTCOracleAddress} already set to xSolvBTC ${xSolvBTCAddresses[network.name]}`);
  } else {
    const setOracleTx = await xSolvBTC.setOracle(xSolvBTCOracleAddress);
    console.log(`xSolvBTCOracle ${xSolvBTCOracleAddress} set to xSolvBTC ${xSolvBTCAddresses[network.name]} at tx: ${setOracleTx.hash}`);
    await setOracleTx.wait(1);
  }
};

module.exports.tags = ['SetXSolvBTCOracle']
