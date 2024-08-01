const factoryHelpers = require('../helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "SolvBTC Yield Pool";
  const implementation = (await deployments.get('SolvBtcYieldPoolImpl')).address;

  await factoryHelpers.setImplementation(productType, implementation);
  await factoryHelpers.deployBeacon(productType);
};

module.exports.tags = ['product_type_YP']
