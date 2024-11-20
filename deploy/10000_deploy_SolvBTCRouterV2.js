const transparentUpgrade = require('./utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();
  const owner = deployer;

  const market = {
    bsctest: '0x929b1B405714ef93CdFFFd6492009baff351f788',
  };

  const fundInfos = {
    bsctest: [
      // [
      //   '0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E', // currency - BTCB
      //   '0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9', // target token - SolvBTC
      //   '0x9f4baed29e08317798d7d50e376733dac70eb6819ab6a843029c138f06cea479', // pool ID
      //   [], // path
      // ],
      [
        '0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9', // currency - SolvBTC
        '0xB4618618b6Fcb61b72feD991AdcC344f43EE57Ad', // target token - SolvBTC.BBN
        '0xaf3b2b789b70339ac56f23c2c8bfd0edd2b1b496f174aefa46880e011fc86187', // pool ID
        [], // path
      ],
      [
        '0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9', // currency - SolvBTC
        '0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c', // target token - SolvBTC.ENA
        '0xc0aefb6754da0510f31decd714b5b3f349b4bf1875c1ab6ddafedba6f33d3e72', // pool ID
        [], // path
      ]
    ]
  };

  const contractName = 'SolvBTCRouterV2';
  const firstImplName = contractName + 'Impl';
  const proxyName = contractName + 'Proxy';

  const versions = {}
  const upgrades = versions[network.name]?.map(v => {return firstImplName + '_' + v}) || []

  const { proxy, newImpl, newImplName } = await transparentUpgrade.deployOrUpgrade(
    firstImplName,
    proxyName,
    {
      contract: contractName,
      from: deployer,
      log: true
    },
    {
      initializer: { 
        method: "initialize", 
        args: [ owner ] 
      },
      upgrades: upgrades
    }
  );

  const SolvBTCRouterV2Factory = await ethers.getContractFactory("SolvBTCRouterV2", deployer);
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(proxy.address);
  
  // const setMarketTx = await solvBTCRouterV2.setOpenFundMarket(market[network.name]);
  // console.log(`Set OpenFundMarket ${market[network.name]} at tx: ${setMarketTx.hash}`);
  // await setMarketTx.wait(1);

  for (let fundInfo of fundInfos[network.name]) {
    const setPoolIdTx = await solvBTCRouterV2.setPoolId(fundInfo[1], fundInfo[0], fundInfo[2]);
    console.log(`Set PoolInfo at tx: ${setPoolIdTx.hash}`);
    await setPoolIdTx.wait(1);

    const setPathTx = await solvBTCRouterV2.setPath(fundInfo[0], fundInfo[1], fundInfo[3]);
    console.log(`Set Path at tx: ${setPathTx.hash}`);
    await setPathTx.wait(1);
  }

};

module.exports.tags = ['SolvBTCRouterV2']
