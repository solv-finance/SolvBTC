const transparentUpgrade = require("../utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const withdrawFeeRate = 5; // 0.05%

  // set WithdrawFeeRate in pool if needed
  const XSolvBTCPoolFactory = await ethers.getContractFactory("XSolvBTCPool", deployer);
  const xSolvBTCPoolAddress = await deployments.get('XSolvBTCPoolProxy').then(d => d.address);
  const xSolvBTCPool = XSolvBTCPoolFactory.attach(xSolvBTCPoolAddress);
  const currentWithdrawFeeRate = await xSolvBTCPool.withdrawFeeRate();
  if (currentWithdrawFeeRate != withdrawFeeRate) {
    const setWithdrawFeeRateTx = await xSolvBTCPool.setWithdrawFeeRateOnlyAdmin(withdrawFeeRate);
    console.log(`WithdrawFeeRate set to ${withdrawFeeRate} at tx: ${setWithdrawFeeRateTx.hash}`);
    await setWithdrawFeeRateTx.wait(1);
  }
};

module.exports.tags = ["SetWithdrawFee"];
