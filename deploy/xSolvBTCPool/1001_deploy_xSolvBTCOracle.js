const { ethers } = require("hardhat");
const transparentUpgrade = require("../utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const navDecimals = 18;
  const initNav = ethers.utils.parseEther("1");

  const contractName = "XSolvBTCOracle";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {
    dev_sepolia: ["v1.2"],
    sepolia: ["v1.1", "v1.2"],
    bsctest: ["v1.1", "v1.2"],
    mantle: ["v1.1"],
    bob: ["v1.1"],
    bera: ["v1.1"],
  };
  const upgrades =
    versions[network.name]?.map((v) => {
      return firstImplName + "_" + v;
    }) || [];

  const { proxy, newImpl, newImplName } =
    await transparentUpgrade.deployOrUpgrade(
      firstImplName,
      proxyName,
      {
        contract: contractName,
        from: deployer,
        log: true,
      },
      {
        initializer: {
          method: "initialize",
          args: [navDecimals, initNav],
        },
        upgrades: upgrades,
      }
    );

  const xSolvBTCOracleFactory = await ethers.getContractFactory(
    "XSolvBTCOracle",
    deployer
  );
  const xSolvBTCOracle = xSolvBTCOracleFactory.attach(proxy.address);

  // set xSolvBTC in oracle if needed
  const xSolvBTCAddress = require("./1099_export_xSolvBTCPoolInfos")
    .XSolvBTCInfos[network.name].token;
  const currentXSolvBTCInOracle = await xSolvBTCOracle.xSolvBTC();
  if (currentXSolvBTCInOracle === xSolvBTCAddress) {
    console.log(
      `xSolvBTC ${xSolvBTCAddress} already set to oracle ${proxy.address}`
    );
  } else {
    const setXSolvBTCTx = await xSolvBTCOracle.setXSolvBTC(xSolvBTCAddress);
    console.log(
      `xSolvBTC ${xSolvBTCAddress} set to oracle ${proxy.address} at tx: ${setXSolvBTCTx.hash}`
    );
    await setXSolvBTCTx.wait(1);
  }

  // set xSolvBTCPool in oracle if needed
  const xSolvBTCPoolAddress = await deployments
    .get("XSolvBTCPoolProxy")
    .then((d) => d.address);
  const currentXSolvBTCPoolInOracle = await xSolvBTCOracle.xSolvBTCPool();
  if (currentXSolvBTCPoolInOracle === xSolvBTCPoolAddress) {
    console.log(
      `xSolvBTCPool ${xSolvBTCPoolAddress} already set to oracle ${proxy.address}`
    );
  } else {
    const setXSolvBTCPoolTx = await xSolvBTCOracle.setXSolvBTCPool(
      xSolvBTCPoolAddress
    );
    console.log(
      `xSolvBTCPool ${xSolvBTCPoolAddress} set to oracle ${proxy.address} at tx: ${setXSolvBTCPoolTx.hash}`
    );
    await setXSolvBTCPoolTx.wait(1);
  }
};

module.exports.tags = ["xSolvBTCOracle"];
