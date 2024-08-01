const colors = require('colors');

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  const governor = deployer

  const instance = await deploy('SftWrappedTokenFactory', {
    contract: 'SftWrappedTokenFactory',
    from: deployer,
    log: true,
    args: [ governor ]
  });
  console.log(`* INFO: ${colors.yellow(`SftWrappedTokenFactory`)} deployed at ${colors.green(instance.address)} on ${colors.red(network.name)}`);
  
};

module.exports.tags = ['SftWrappedTokenFactory']
