const transparentUpgrade = require('../utils/transparentUpgrade');

module.exports = async ({ getNamedAccounts, deployments, network }) => {

  const { deployer } = await getNamedAccounts();

  const BroRouterFactory = await ethers.getContractFactory("BRORouter", deployer);
  const broRouterAddress = (await deployments.get('BRORouterProxy')).address;
  const broRouter = BroRouterFactory.attach(broRouterAddress);
  
  const sft = "0x1bdA9d2d280054C5CF657B538751dD3bB88671e3";
  const sftSlot = "77490893808118283831741446642904681173330829094617591694418336651036418175900";
  const broToken = (await deployments.get('BRO-SolvBTC-01MAR2026')).address;

  const setBroTokenTx = await broRouter.setBroToken(sft, sftSlot, broToken);
  console.log(`Set BroToken ${broToken} at tx: ${setBroTokenTx.hash}`);
  await setBroTokenTx.wait(1);

};

module.exports.tags = ['SetBroToken']
