const factoryHelpers = require('./helpers/factoryHelpers');

module.exports = async ({ deployments }) => {

  const productType = "Open-end Fund Share Wrapped Token";
  const implementation = (await deployments.get('SftWrappedTokenImpl_v1.1')).address;

  await factoryHelpers.setImplementation(productType, implementation);
  await factoryHelpers.upgradeBeacon(productType);
};

module.exports.tags = ['product_type_OFS_WrappedToken_upgrade']
