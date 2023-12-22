const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const productName = "SWT Multi-currency";
  const tokenName = "SftWrappedToken MultiCurrency";
  const tokenSymbol = "SWT-MultiCurrency";
  const wrappedSft = "0x6089795791F539d664F403c4eFF099F48cE17C75";
  const wrappedSlot = "94872245356118649870025069682337571253044538568877833354046341235689653624276";
  const navOracle = "0x18937025Dffe1b5e9523aa35dEa0EE55dae9D675";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['product_SWT_MultiCurrency']
