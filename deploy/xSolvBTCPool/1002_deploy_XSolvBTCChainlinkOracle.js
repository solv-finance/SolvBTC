const { ethers } = require('hardhat');
const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const contractName = 'XSolvBTCChainlinkOracle';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const chainlinkAggregators = {
    mainnet: '0x46cE854814ea38A4857AeA23aE7759b3A7970e4a',
    bsc: '0x68ff0d4499c68Cf4471143930422ae8F17f6Cd58',
    arb: '0xAE8B4179389059A735821A77417eACcA60f3e4B4',
    avax: '0x55b5dc7d7CDD5d3b2Eb189bf11140839076E5d40',
    base: '0x17738F7dacFc1De7d06f22cC52211EBf68744dBA',
    bob: '0xDaFC998d008f0b503Fe84102281B36631543DB9C',
    sonic: '0x5c042362ecB555D9fb554E4ee1821Aa6762D9239',
    soneium: '0x42237D7d96A4178bB22498bb3B2C689D502DE847',
    linea: '0x49768d7ebB7694b1e72546300cCCeD877084d72f',
  };

  const versions = {}
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const { proxy, newImpl, newImplName } = await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
      log: true
    },
    {
      initializer: { 
        method: "initialize", 
        args: [ chainlinkAggregators[network.name] ] 
      },
      upgrades: upgrades
    }
  );

  const OracleFactory = await ethers.getContractFactory("XSolvBTCChainlinkOracle", deployer);
  const oracle = OracleFactory.attach(proxy.address);
  const xSolvBTCAddresses = {
    mainnet: '0xd9D920AA40f578ab794426F5C90F6C731D159DEf',
    bsc: '0x1346b618dC92810EC74163e4c27004c921D446a5',
    arb: '0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB',
    avax: '0xCC0966D8418d412c599A6421b760a847eB169A8c',
    base: '0xC26C9099BD3789107888c35bb41178079B282561',
    bob: '0xCC0966D8418d412c599A6421b760a847eB169A8c',
    sonic: '0xCC0966D8418d412c599A6421b760a847eB169A8c',
    soneium: '0xCC0966D8418d412c599A6421b760a847eB169A8c',
    linea: '0xCC0966D8418d412c599A6421b760a847eB169A8c',
  }

  if (xSolvBTCAddresses[network.name]) {
    const currentXSolvBTCAddress = await oracle.xSolvBTC();
    if (currentXSolvBTCAddress === xSolvBTCAddresses[network.name]) {
      console.log(`xSolvBTC ${xSolvBTCAddresses[network.name]} already set to xSolvBTCChainlinkOracle ${oracle.address}`);
    } else {
      const setXSolvBTCTx = await oracle.setXSolvBTC(xSolvBTCAddresses[network.name]);
      console.log(`xSolvBTC ${xSolvBTCAddresses[network.name]} set to xSolvBTCChainlinkOracle ${oracle.address} at tx: ${setXSolvBTCTx.hash}`);
      await setXSolvBTCTx.wait(1);
    }
  }
};

module.exports.tags = ['xSolvBTCChainlinkOracle']
