const transparentUpgrade = require("./utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const tokenInfos = require("./SolvBTC/10099_export_SolvBTCInfos");

  const solvBTCAddress = tokenInfos.SolvBTCInfos[network.name].erc20;
  const defaultFeeRecipient = "0x5ef01B1eFfA34Bdd3A305a968A907108D52FF234";
  const defaultWithdrawFeeRate = 50; // 0.5%

  const customFeeInfos = {
    dev_sepolia: {
      admin: deployer,
      redemptionVault: "0x195a4b5a35d0729394d5603deb9aab941ec1e7ec",
      btcPlus: "0xBfE4B499B55084da6a0dA89E0254893B241Dca18",
      feeRecipient: defaultFeeRecipient,
      withdrawFeeRate: defaultWithdrawFeeRate,
    },
  };

  const feeRecipient =
    customFeeInfos[network.name]?.feeRecipient || defaultFeeRecipient;
  const withdrawFeeRate =
    customFeeInfos[network.name]?.withdrawFeeRate || defaultWithdrawFeeRate;

  const contractName = "BTCPlusRedeem";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {
    dev_sepolia: ["v1.1", "v1.2"],
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
          args: [
            customFeeInfos[network.name].admin,
            customFeeInfos[network.name].redemptionVault,
            solvBTCAddress,
            customFeeInfos[network.name].btcPlus,
            feeRecipient,
          ],
        },
        upgrades: upgrades,
      }
    );

  // set MaxMultiplier in pool if needed
  const BTCPlusRedeemFactory = await ethers.getContractFactory(
    "BTCPlusRedeem",
    deployer
  );
  const btcPlusRedeem = BTCPlusRedeemFactory.attach(proxy.address);
  const currentWithdrawFeeRate = await btcPlusRedeem.withdrawFeeRate();
  if (currentWithdrawFeeRate != withdrawFeeRate) {
    const setWithdrawFeeRateTx = await btcPlusRedeem.setWithdrawFeeRate(
      withdrawFeeRate
    );
    console.log(
      `withdrawFeeRate set to ${withdrawFeeRate} at tx: ${setWithdrawFeeRateTx.hash}`
    );
    await setWithdrawFeeRateTx.wait(1);
  }
};

module.exports.tags = ["BTCPlusRedeem"];
