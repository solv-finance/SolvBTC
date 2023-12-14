const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const instance = await deploy('SftWrappedTokenImpl', {
    contract: 'SftWrappedToken',
    from: deployer,
    log: true,
  });
  console.log(`* INFO: ${colors.yellow(`SftWrappedToken`)} deployed at ${colors.green(instance.address)} on ${colors.red(network.name)}`);

};

module.exports.tags = ['SWT_impl']
