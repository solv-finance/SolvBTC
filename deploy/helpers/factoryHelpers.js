const colors = require('colors');
const { txWait } = require('./deployUtils');

const getSftWrappedTokenFactory = async () => {
  const { deployer } = await getNamedAccounts();
  const swtFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory', deployer);
  const swtFactoryAddress = (await deployments.get('SftWrappedTokenFactory')).address;
  return swtFactoryFactory.attach(swtFactoryAddress);
}

const setImplementation = async (productType, implementation) => {
  const swtFactory = await getSftWrappedTokenFactory();
  const setImplTx = await swtFactory.setImplementation(productType, implementation);
  console.log(`* INFO: SftWrappedTokenFactory set implementation ${implementation} for productType "${productType}" at tx ${setImplTx.hash}`);
  await txWait(setImplTx);
}

const deployBeacon = async (productType) => {
  const swtFactory = await getSftWrappedTokenFactory();
  const deployBeaconTx = await swtFactory.deployBeacon(productType);
  console.log(`* INFO: SftWrappedTokenFactory deploy beacon for productType "${productType}" at tx ${deployBeaconTx.hash}`);
  await txWait(deployBeaconTx);

  const beaconAddress = await swtFactory.getBeacon(productType);
  console.log(`* INFO: Beacon for productType "${productType}" deployed at ${colors.green(beaconAddress)}`);
  return beaconAddress;
}
 
const upgradeBeacon = async (productType) => {
  const swtFactory = await getSftWrappedTokenFactory();
  const upgradeBeaconTx = await swtFactory.upgradeBeacon(productType);
  console.log(`* INFO: SftWrappedTokenFactory upgrade beacon for productType "${productType}" at tx ${upgradeBeaconTx.hash}`);
  await txWait(upgradeBeaconTx);
}

const deployProxy = async (productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle) => {
  const swtFactory = await getSftWrappedTokenFactory();
  const deployProxyTx  = await swtFactory.deployProductProxy(productType, productName, tokenName, tokenSymbol, wrappedSft, wrappedSlot, navOracle);
  console.log(`* INFO: SftWrappedTokenFactory deploy proxy for productType "${productType}" & productName "${productName}" at tx ${deployProxyTx.hash}`);
  await txWait(deployProxyTx);

  const proxyAddress = await swtFactory.getProxy(productType, productName);
  console.log(`* INFO: "${productName}" deployed at ${colors.green(proxyAddress)}`);
  return proxyAddress;
}

module.exports = {
  getSftWrappedTokenFactory,
  setImplementation,
  deployBeacon,
  upgradeBeacon,
  deployProxy,
}