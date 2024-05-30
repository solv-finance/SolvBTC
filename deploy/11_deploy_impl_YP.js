const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const version = '';

  const instance = await deploy('SolvBtcYieldPoolImpl' + version, {
    contract: 'SftWrappedToken',
    from: deployer,
    log: true,
  });
  console.log(`* INFO: ${colors.yellow(`SolvBtcYieldPoolImpl`)} deployed at ${colors.green(instance.address)} on ${colors.red(network.name)}`);

};

module.exports.tags = ['YP_impl']
