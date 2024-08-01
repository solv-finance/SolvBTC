const transparentUpgrade = require('../utils/transparentUpgrade');
const gasTracker = require('../utils/gasTracker');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const gasPrice = await gasTracker.getGasPrice(network.name);

  const governor = deployer;
  const market = {
    dev_sepolia: '0x109198Eb8BD3064Efa5d0711b505f59cFd77de18',
    sepolia: '0x91967806F47e2c6603C9617efd5cc91Bc2A7473E',
    merlin_test: '0xA853A738d3D86e1cd24b79bdB16916F57e8F9886',
    blast_test: '0xf4280ab5e1868ab3492afd02bF7692D5780baAeA',
    ailayer_test: '0x60680f8921E50c25A8030F4175C5d12C91Ee1Fe9',
    bob_test: '0x60680f8921E50c25A8030F4175C5d12C91Ee1Fe9',

    mainnet: '0x57bB6a8563a8e8478391C79F3F433C6BA077c567',
    arb: '0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8',
    bsc: '0xaE050694c137aD777611286C316E5FDda58242F3',
    merlin: '0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf',
    mantle: '0x1210371F2E26a74827F250afDfdbE3091304a3b7',
    ailayer: '0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf',
    avax: '0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf',
  };
  const solvBTCYieldTokenMultiAssetPool = (await deployments.get('SolvBTCYieldTokenMultiAssetPoolProxy')).address;

  const contractName = 'SolvBTCRouter';
  const firstImplName = 'SolvBTCYieldTokenRouterImpl';
  const proxyName = 'SolvBTCYieldTokenRouterProxy';

  const versions = {}
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
        args: [ governor, market[network.name], solvBTCYieldTokenMultiAssetPool ] 
      },
      upgrades: upgrades
    }
  );
};

module.exports.tags = ['SolvBTCYTRouter']
