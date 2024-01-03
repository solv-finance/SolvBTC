const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";

  /* dev-goerli: Multi-currency */
  // const productName = "SWT Multi-currency";
  // const tokenName = "SftWrappedToken MultiCurrency";
  // const tokenSymbol = "SWT-MultiCurrency";
  // const wrappedSft = "0x6089795791F539d664F403c4eFF099F48cE17C75";
  // const wrappedSlot = "94872245356118649870025069682337571253044538568877833354046341235689653624276";
  // const navOracle = "0x18937025Dffe1b5e9523aa35dEa0EE55dae9D675";

  /* testnet-goerli: Multi-currency */
  const productName = "SWT Multi-currency";
  const tokenName = "SftWrappedToken MultiCurrency";
  const tokenSymbol = "SWT-MultiCurrency";
  const wrappedSft = "0xb8994C337993403fd6Dc726D35b3b55cE67c097e";
  const wrappedSlot = "48718224937827895671684825076639510596151333960208891715050581886087643969895";
  const navOracle = "0x9131F8cd0E5Ef7C28eC2D71FFFfA62788e51111b";

  await factoryHelpers.deployProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);

};

module.exports.tags = ['product_SWT_MultiCurrency']
