const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");
const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const marketAbi = [
    "function updateFundraisingEndTime(bytes32 poolId, uint64 newEndTime)",
    "function governor() view returns (address)",
    "function poolInfos(bytes32 poolId) view returns ((address,address,uint256,uint256),(uint16,address,uint64),(address,address,address),(uint256,uint256,uint256,uint64,uint64),address,address,address,uint64,bool,uint256)",
  ];

  const marketAddress = require("../SolvBTC/10099_export_SolvBTCInfos").OpenFundMarketAddresses[network.name];
  const solvBTCMultiAssetPoolAddress = require("../SolvBTC/10099_export_SolvBTCInfos").SolvBTCMultiAssetPoolAddresses[network.name];
  const lstMultiAssetPoolAddress = require("../SolvBTCYieldToken/20099_export_SolvBTCYTInfos").SolvBTCYieldTokenMultiAssetPoolAddresses[network.name];
  const xSolvBTCPoolAddress = (await deployments.getOrNull('XSolvBTCPoolProxy'))?.address;

  const MarketFactory = await ethers.getContractFactory(marketAbi, deployer);
  const MultiAssetPoolFactory = await ethers.getContractFactory("SolvBTCMultiAssetPool", deployer);
  const XSolvBTCPoolFactory = await ethers.getContractFactory("XSolvBTCPool", deployer);

  const pauseInfos = {
    bsc: [
      [ 352, "SolvBTC.BERA", "lst pool", "0xb816018e5d421e8b809a4dc01af179d86056ebdf", "70222896071207762779953378931956679402408390821663654047017958775368527671200" ],
    ],
    mantle: [
      [ 180, "SolvBTC", "solvbtc pool", "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce", "71875420614193724644548223076121034603956938221596243170032844961259965130427"],
      [ 181, "xSolvBTC", "xpool"],
    ],
    avax: [
      [ 183, "SolvBTC", "solvbtc pool", "0x6b2e555b6c17bfbba251cc3cde084071f4a7ef38", "11855698383361531140241834848840694583099560042595010827827423787557845170628"],
      [ 185, "xSolvBTC", "xpool"],
      [ 377, "BTC+", "market", "0x2af9049acd74a38a57bf5299463042bd2b9a8d525bfbbe640f84d099651a77fc"],
    ],
    bera: [
      [ 354, "SolvBTC", "solvbtc pool", "0x1f4d23513c3ef0d63b97bbd2ce7c845ebb1cf1ce", "73054730711870722933844565498985369099913996007027537845134272683003526055870" ],
      [ 355, "xSolvBTC", "xpool" ],
      [ 375, "BTC+", "market", "0x7f712c24cedabb020f303f07650d19c94a93d71ca928ed614ece8b15aef85150" ],
      [ 356, "SolvBTC.BERA", "lst pool", "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae", "20070464631911807053851373235364630027197982269692303312604928304223800691939" ],
    ],
    base: [
      [ 199, "xSolvBTC", "xpool" ],
    ],
    linea: [
      [ 238, "SolvBTC", "solvbtc pool", "0x6b2e555b6c17bfbba251cc3cde084071f4a7ef38", "84531624719859354378327451138171545523855830645841752756364351502579237121040" ],
      [ 239, "xSolvBTC", "lst pool", "0x29f870ed75b4632301946bb935433605f39d515e", "63950668890804329480931069325915123854394556555578485584971294316396625135919" ],
    ],
    ink: [
      [ 345, "xSolvBTC", "lst pool", "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae", "21878350592799687335720143765034541687231338182764106208669036308924224432770" ],
    ],
    hyperevm: [
      [ 360, "SolvBTC", "market", "0x8f7c9f7133da42e0610c8e4ac4cd06d183c8315b8c68632d5ca825eab62b1d51" ],
      [ 361, "xSolvBTC", "lst pool", "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae", "64660756677022162747895226196603521883866945560585298210931262666368174652736" ],
      [ 376, "BTC+", "market", "0x3d531b19bb21df9f08e2327e0acf63dd9ae416e782acbc3683cfd1851a536d15" ],
      [ 362, "SolvBTC.BNB", "market", "0xa055402e0286dee50dd8e31a2fc495fe64e0035edf83bc4dd3477bacb6339d20" ],
    ],
    rootstock: [
      [ 334, "SolvBTC", "market", "0xf565aa1c019284a525d3157a65249ab8eae5792d52607b5469304b883afe1298" ],
      [ 333, "xSolvBTC", "lst pool", "0x29f870ed75b4632301946bb935433605f39d515e", "62817733643116395134583342160513164074164336605273283322054884601625839828996" ],
      [ 386, "BTC+", "lst pool", "0x29f870ed75b4632301946bb935433605f39d515e", "97075096825935347873451002273595650358517702021537590436500585382048116226529" ],
    ],
    soneium: [
      [ 335, "SolvBTC", "market", "0x24c57463cb22eb61e11661ac83df852fa4cd28ac4760dcc465cdfebebef8cd6d" ],
      [ 336, "xSolvBTC", "lst pool", "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae", "61223509085126765638810124921947600293064955381636991311628229057592425317222" ],
    ],
    core: [
      [ 207, "SolvBTC.CORE", "lst pool", "0x29f870ed75b4632301946bb935433605f39d515e", "59819322140113552725122614460770587161987797451671393895736157918548287005178" ],
    ],
    merlin: [
      [ 138, "xSolvBTC", "lst pool", "0x788dc3af7b62708b752d483a6e30d1cf23c3eaae", "23002376000286537971644610945217253049745413385836602646876543302447601012196" ],
      [ 106, "SolvBTC.MERL", "market", "0xdb76947333de76435723149d54aefc7c0eeea3c2ca8b763b315f4298aef33c37" ],
    ],
  }

  for (let info of pauseInfos[network.name]) {
    switch (info[2]) {
      case "solvbtc pool":
        const solvBTCPool = MultiAssetPoolFactory.attach(solvBTCMultiAssetPoolAddress);
        console.log(colors.yellow(`Chain: ${network.name}, Fund ID: ${info[0]}, Product: ${info[1]}, Contract: ${info[2]} at ${solvBTCPool.address}`));
        let currentSolvBTCDepositStatus = await solvBTCPool.isSftSlotDepositAllowed(info[3], info[4]);
        let currentSolvBTCWithdrawStatus = await solvBTCPool.isSftSlotWithdrawAllowed(info[3], info[4]);
        if (!currentSolvBTCDepositStatus && !currentSolvBTCWithdrawStatus) {
          console.log(colors.green("  Already paused"));
        } else {
          const admin = await solvBTCPool.admin();
          if (admin != deployer) {
            console.log(colors.blue(`  Operator is not admin ${admin}`));
          } else {
            const pauseSolvBTCTx = await solvBTCPool.changeSftSlotAllowedOnlyAdmin(info[3], info[4], false, false);
            console.log(colors.green(`  Pausing at ${pauseSolvBTCTx.hash}`));
            await pauseSolvBTCTx.wait();
          }
        }
        break;

      case "lst pool":
        const lstMultiAssetPool = MultiAssetPoolFactory.attach(lstMultiAssetPoolAddress);
        console.log(colors.yellow(`Chain: ${network.name}, Fund ID: ${info[0]}, Product: ${info[1]}, Contract: ${info[2]} at ${lstMultiAssetPool.address}`));
        let currentLstSolvBTCDepositStatus = await lstMultiAssetPool.isSftSlotDepositAllowed(info[3], info[4]);
        let currentLstSolvBTCWithdrawStatus = await lstMultiAssetPool.isSftSlotWithdrawAllowed(info[3], info[4]);
        if (!currentLstSolvBTCDepositStatus && !currentLstSolvBTCWithdrawStatus) {
          console.log(colors.green("  Already paused"));
        } else {
          const admin = await lstMultiAssetPool.admin();
          if (admin != deployer) {
            console.log(colors.blue(`  Operator is not admin ${admin}`));
          } else {
            const pauseLstSolvBTCTx = await lstMultiAssetPool.changeSftSlotAllowedOnlyAdmin(info[3], info[4], false, false);
            console.log(colors.green(`  Pausing at ${pauseLstSolvBTCTx.hash}`));
            await pauseLstSolvBTCTx.wait();
          }
        }
        break;

      case "xpool":
        const xSolvBTCPool = XSolvBTCPoolFactory.attach(xSolvBTCPoolAddress);
        console.log(colors.yellow(`Chain: ${network.name}, Fund ID: ${info[0]}, Product: ${info[1]}, Contract: ${info[2]} at ${xSolvBTCPool.address}`));
        let currentXSolvBTCDepositStatus = await xSolvBTCPool.depositAllowed();
        if (!currentXSolvBTCDepositStatus) {
          console.log(colors.green("  Already paused"));
        } else {
          const admin = await xSolvBTCPool.admin();
          if (admin != deployer) {
            console.log(colors.blue(`  Operator is not admin ${admin}`));
          } else {
            const pauseXSolvBTCTx = await xSolvBTCPool.setDepositAllowedOnlyAdmin(false);
            console.log(colors.green(`  Pausing at ${pauseXSolvBTCTx.hash}`));
            await pauseXSolvBTCTx.wait();
          }
        }
        break;

      case "market":
        const market = MarketFactory.attach(marketAddress);
        console.log(colors.yellow(`Chain: ${network.name}, Fund ID: ${info[0]}, Product: ${info[1]}, Contract: ${info[2]} at ${marketAddress}`));
        let poolInfo = await market.poolInfos(info[3]);
        let currentEndTime = poolInfo[3][4];
        let nowTime = Date.now() / 1000;
        if (currentEndTime <= nowTime) {
          console.log(colors.green("  Already paused"));
        } else {
          const governor = await market.governor();
          if (governor != deployer) {
            console.log(colors.blue(`  Operator is not governor ${governor}`));
          } else {
            const pauseMarketTx = await market.updateFundraisingEndTime(info[3], 1764547200);  // 2025-12-01 00:00:00 UTC
            console.log(colors.green(`  Pausing at ${pauseMarketTx.hash}`));
            await pauseMarketTx.wait();
          }
        }
        break;

      default:
        console.log(colors.red(`Chain: ${network.name}, Fund ID: ${info[0]}, Product: ${info[1]}, Contract: ${info[2]} Pause Unknown`));
        break;
    }
  }

};

module.exports.tags = ["PauseFund"];
