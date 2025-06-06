const transparentUpgrade = require("../utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const tokenInfos = require("./1099_export_xSolvBTCPoolInfos");

  const solvBTCAddress = tokenInfos.SolvBTCAddresses[network.name];
  const xSolvBTCAddress = tokenInfos.XSolvBTCInfos[network.name].token;

  const defaultFeeRecipient = "0x5ef01B1eFfA34Bdd3A305a968A907108D52FF234";
  const defaultWithdrawFeeRate = 20; // 0.2%

  const customFeeInfos = {
    dev_sepolia: {
      feeRecipient: deployer,
      withdrawFeeRate: 100, // 1%
    },
    sepolia: {
      feeRecipient: deployer,
      withdrawFeeRate: 100, // 1%
    },
    bsctest: {
      feeRecipient: deployer,
      withdrawFeeRate: 100, // 1%
    },
    bob: {
      feeRecipient: "0xA26DDC188B1C07d7F0dcb90827424b14DDa2e372",
      withdrawFeeRate: 20, // 0.2%
    },
  };

  const feeRecipient =
    customFeeInfos[network.name]?.feeRecipient || defaultFeeRecipient;
  const withdrawFeeRate =
    customFeeInfos[network.name]?.withdrawFeeRate || defaultWithdrawFeeRate;

  const contractName = "XSolvBTCPool";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {};
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
          args: [
            solvBTCAddress,
            xSolvBTCAddress,
            feeRecipient,
            withdrawFeeRate,
          ],
        },
        upgrades: upgrades,
      }
    );
};

module.exports.tags = ["xSolvBTCPool"];
