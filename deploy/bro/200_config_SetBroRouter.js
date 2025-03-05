const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const BroRouterFactory = await ethers.getContractFactory("BRORouter", deployer);
  const broRouterAddress = (await deployments.get('BRORouterProxy')).address;
  const broRouter = BroRouterFactory.attach(broRouterAddress);
  
  const broInfos = {
    dev_sepolia: {
      symbol: "BRO-SolvBTC-01MAR2026",
      wrappedSft: "0x1bdA9d2d280054C5CF657B538751dD3bB88671e3",
      wrappedSlot: "77490893808118283831741446642904681173330829094617591694418336651036418175900",
    },
    sepolia: {
      symbol: "BRO-Solv-06MAR2026",
      wrappedSft: "0xB85A099103De07AC3d2C498453a6599D273be701",
      wrappedSlot: "72110313783316139196413968141577714773041221224557351580978746098402329850088",
    }
  }

  const broInfo = broInfos[network.name];
  const broToken = (await deployments.get(broInfo.symbol)).address;

  const currentBroToken = await broRouter.broTokens(broInfo.wrappedSft, broInfo.wrappedSlot);
  if (currentBroToken.toLowerCase() == broToken.toLowerCase()) {
    console.log(`BroToken ${broToken} already set`);
  } else {
    const setBroTokenTx = await broRouter.setBroToken(broInfo.wrappedSft, broInfo.wrappedSlot, broToken);
    console.log(`Set BroToken ${broToken} at tx: ${setBroTokenTx.hash}`);
    await setBroTokenTx.wait(1);
  }

};

module.exports.tags = ['SetBroRouter']
