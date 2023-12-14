const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const governor = deployer

  const instance = await deploy('SftWrappedTokenFactory', {
    contract: 'SftWrappedTokenFactory',
    from: deployer,
    log: true,
  });
  console.log(`* INFO: ${colors.yellow(`SftWrappedTokenFactory`)} deployed at ${colors.green(instance.address)} on ${colors.red(network.name)}`);

  const SWTFactoryFactory = await ethers.getContractFactory('SftWrappedTokenFactory');
  const swtFactory = await SWTFactoryFactory.attach(instance.address);
  const initTx = await swtFactory.initialize(governor);
  console.log(`* INFO: SftWrappedTokenFactory initialized at tx ${initTx.hash}`);
};

module.exports.tags = ['SftWrappedTokenFactory']
