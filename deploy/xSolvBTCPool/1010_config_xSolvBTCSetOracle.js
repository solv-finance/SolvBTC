module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const xSolvBTCFactory = await ethers.getContractFactory("SolvBTCYieldTokenV3_1", deployer);
  const xSolvBTCAddress = require('./1099_export_xSolvBTCPoolInfos').XSolvBTCInfos[network.name].token;
  const xSolvBTC = xSolvBTCFactory.attach(xSolvBTCAddress);

  const xSolvBTCOracleAddress = (await deployments.get("XSolvBTCOracleProxy")).address;

  const currentOracle = await xSolvBTC.getOracle();
  if (currentOracle === xSolvBTCOracleAddress) {
    console.log(`xSolvBTCOracle ${xSolvBTCOracleAddress} already set to xSolvBTC ${xSolvBTCAddress}`);
  } else {
    const setOracleTx = await xSolvBTC.setOracle(xSolvBTCOracleAddress);
    console.log(`xSolvBTCOracle ${xSolvBTCOracleAddress} set to xSolvBTC ${xSolvBTCAddress} at tx: ${setOracleTx.hash}`);
    await setOracleTx.wait(1);
  }
};

module.exports.tags = ['xSolvBTCSetOracle']
