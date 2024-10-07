const colors = require("colors");
const { txWait } = require("../utils/deployUtils");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const SolvBTCYieldTokenFactoryFactory = await ethers.getContractFactory(
    "SolvBTCFactory",
    deployer
  );
  const solvBTCYieldTokenFactoryAddress = (
    await deployments.get("SolvBTCYieldTokenFactory")
  ).address;
  const solvBTCYieldTokenFactory = SolvBTCYieldTokenFactoryFactory.attach(
    solvBTCYieldTokenFactoryAddress
  );

  const productType = "SolvBTC Yield Token";
  const productName = "SolvBTC Jupiter";
  const tokenName = "SolvBTC Jupiter";
  const tokenSymbol = "SolvBTC.JUP";

  let proxyAddress = await solvBTCYieldTokenFactory.getProxy(
    productType,
    productName
  );
  if (proxyAddress == ethers.constants.AddressZero) {
    const deployProxyTx = await solvBTCYieldTokenFactory.deployProductProxy(
      productType,
      productName,
      tokenName,
      tokenSymbol
    );
    console.log(`* INFO: Deploy ${tokenSymbol} at ${deployProxyTx.hash}`);
    await txWait(deployProxyTx);

    proxyAddress = await solvBTCYieldTokenFactory.getProxy(
      productType,
      productName
    );
    console.log(
      `* INFO: ${tokenSymbol} deployed at ${colors.yellow(proxyAddress)}`
    );
  } else {
    console.log(
      `* INFO: ${tokenSymbol} already deployed at ${colors.yellow(
        proxyAddress
      )}`
    );
  }

  const SolvBTCYieldTokenFactory_ = await ethers.getContractFactory(
    "SolvBTCYieldToken",
    deployer
  );
  const solvBTCYieldTokenAddress = await solvBTCYieldTokenFactory.getProxy(
    productType,
    productName
  );
  const solvBTCYieldToken = SolvBTCYieldTokenFactory_.attach(
    solvBTCYieldTokenAddress
  );

  // execute `initializeV2` for SolvBTCYieldToken
  const poolAddressInSolvBTC = await solvBTCYieldToken.solvBTCMultiAssetPool();
  if (poolAddressInSolvBTC == ethers.constants.AddressZero) {
    const solvBTCYieldPoolMultiAssetPoolAddress = (
      await deployments.get("SolvBTCYieldTokenMultiAssetPoolProxy")
    ).address;
    const initializeV2Tx = await solvBTCYieldToken.initializeV2(
      solvBTCYieldPoolMultiAssetPoolAddress
    );
    console.log(`* INFO: SolvBTC.CORE initializeV2 at ${initializeV2Tx.hash}`);
    await txWait(initializeV2Tx);
  } else {
    console.log(`* INFO: ${tokenSymbol} initializeV2 already executed`);
  }

  // set oracle address for SolvBTCYieldToken
  const oracleAddressInSolvBTC = await solvBTCYieldToken.getOracle();
  if (oracleAddressInSolvBTC == ethers.constants.AddressZero) {
    const solvBTCYieldPoolOracleAddress = (
      await deployments.get("SolvBTCYieldTokenOracleForSFTProxy")
    ).address;
    const setOracleTx = await solvBTCYieldToken.setOracle(
      solvBTCYieldPoolOracleAddress
    );
    console.log(
      `* INFO: ${tokenSymbol} setOracle ${solvBTCYieldPoolOracleAddress} at ${setOracleTx.hash}`
    );
    await txWait(setOracleTx);
  } else {
    console.log(`* INFO: ${tokenSymbol} oracle already set`);
  }
};

module.exports.tags = ["SolvBTC_JUP"];
