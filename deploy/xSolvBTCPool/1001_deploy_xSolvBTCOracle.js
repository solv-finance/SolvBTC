const { ethers } = require('hardhat');
const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const navDecimals = 18;

  const contractName = 'XSolvBTCOracle';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

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
        args: [ navDecimals ]
      },
      upgrades: upgrades
    }
  );

  const xSolvBTCOracleFactory = await ethers.getContractFactory("XSolvBTCOracle", deployer);
  const xSolvBTCOracle = xSolvBTCOracleFactory.attach(proxy.address);

  // set xSolvBTC in oracle if needed
  const xSolvBTCAddress = require('./1099_export_xSolvBTCPoolInfos').XSolvBTCInfos[network.name].token;
  const currentXSolvBTCInOracle = await xSolvBTCOracle.xSolvBTC();
  if (currentXSolvBTCInOracle === xSolvBTCAddress) {
    console.log(`xSolvBTC ${xSolvBTCAddress} already set to oracle ${proxy.address}`);
  } else {
    const setXSolvBTCTx = await xSolvBTCOracle.setXSolvBTC(xSolvBTCAddress);
    console.log(`xSolvBTC ${xSolvBTCAddress} set to oracle ${proxy.address} at tx: ${setXSolvBTCTx.hash}`);
    await setXSolvBTCTx.wait(1);
  }

};

module.exports.tags = ['xSolvBTCOracle']
