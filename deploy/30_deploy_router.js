const transparentUpgrade = require('./utils/transparentUpgrade');
const gasTracker = require('./utils/gasTracker');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const gasPrice = await gasTracker.getGasPrice(network.name);

  const governor = deployer;
  const market = {
    localhost: '0xdbb35Ba81Dcba6AeC3a28ec127da434A0069A950',
    dev_goerli: '0xdbb35Ba81Dcba6AeC3a28ec127da434A0069A950',
    goerli: '0x2266dc69c2FaCD493C43a52E7c2131f2dF509287',
    arb: '0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8',
    mantle: '0x1210371F2E26a74827F250afDfdbE3091304a3b7',
    eth: '0x57bB6a8563a8e8478391C79F3F433C6BA077c567',
    merlin_test: '0xA853A738d3D86e1cd24b79bdB16916F57e8F9886'
  };
  const factory = (await deployments.get('SftWrappedTokenFactory')).address;

  const contractName = 'SftWrapRouter';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {
    localhost: ['v1.1'],
    dev_goerli: ['v1.1'],
  }

  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const { proxy, newImpl, newImplName } = await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
      gasPrice: gasPrice,
      log: true
    },
    {
      initializer: { 
        method: "initialize", 
        args: [ governor, market[network.name], factory ] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['SftWrapRouter']
