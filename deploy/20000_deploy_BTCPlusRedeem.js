const transparentUpgrade = require("./utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const tokenInfos = require("./SolvBTC/10099_export_SolvBTCInfos");

  const solvBTCAddress = tokenInfos.SolvBTCInfos[network.name].erc20;
  const defaultFeeRecipient = "0x5ef01B1eFfA34Bdd3A305a968A907108D52FF234";
  const defaultWithdrawFeeRate = 50; // 0.5%
  const defaultAdmin = "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D";

  const customFeeInfos = {
    dev_sepolia: {
      admin: deployer,
      redemptionVault: "0x195a4b5a35d0729394d5603deb9aab941ec1e7ec",
      btcPlus: "0xBfE4B499B55084da6a0dA89E0254893B241Dca18",
      feeRecipient: defaultFeeRecipient,
      withdrawFeeRate: defaultWithdrawFeeRate,
    },
    sepolia: {
      admin: deployer,
      redemptionVault: "0x4c18f65f31a305e05b726072ca1676d197eaea27",
      btcPlus: "0x72B6573FCB8d54522C28689e0aA0B6C77fD245ed",
      feeRecipient: defaultFeeRecipient,
      withdrawFeeRate: defaultWithdrawFeeRate,
    },
    arb: {
      admin: defaultAdmin,
      redemptionVault: "0xb26b467028ae4e14a13ec3f77e2e433b48530cd4",
      btcPlus: "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
      feeRecipient: defaultFeeRecipient,
      withdrawFeeRate: 25, // 0.25%
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
    dev_sepolia: ["v1.1", "v1.2", "v1.3"],
  };
  const upgrades = versions[network.name]?.map((v) => { return firstImplName + "_" + v; }) || [];

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

  const BTCPlusRedeemFactory = await ethers.getContractFactory("BTCPlusRedeem", deployer);
  const btcPlusRedeem = BTCPlusRedeemFactory.attach(proxy.address);
  const currentWithdrawFeeRate = await btcPlusRedeem.withdrawFeeRate();
  if (currentWithdrawFeeRate != withdrawFeeRate) {
    const setWithdrawFeeRateTx = await btcPlusRedeem.setWithdrawFeeRate(withdrawFeeRate);
    console.log(`withdrawFeeRate set to ${withdrawFeeRate} at tx: ${setWithdrawFeeRateTx.hash}`);
    await setWithdrawFeeRateTx.wait(1);
  }
};

module.exports.tags = ["BTCPlusRedeem"];
