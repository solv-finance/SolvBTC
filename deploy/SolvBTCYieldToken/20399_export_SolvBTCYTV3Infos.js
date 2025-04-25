const SolvBTCYieldTokenFactoryV3Addresses = {
  dev_sepolia: "0x197cfd48184ADCCa3b061851118c624c22EE59b2",
  sepolia: "0x197cfd48184ADCCa3b061851118c624c22EE59b2",
  ink_test: "0xE081Dd28Dfd3001F851CFb5bA8279F1C2B8b92b5",
  hyperevm_test: "0xE081Dd28Dfd3001F851CFb5bA8279F1C2B8b92b5",
  mainnet: "0x86fC77cfe9F7d6a84097E9B73bd32cA185fdb12a",
  bsc: "",
  avax: "0xd83EDb24948eEfAF30d9b2f30FbDeC90e1cdc25f",
  bob: "",
  soneium: "0xF233c5cac3177c70a554C0178cFA85f61D97622B",
  polygon: "0xd83EDb24948eEfAF30d9b2f30FbDeC90e1cdc25f",
  ink: "0xd83EDb24948eEfAF30d9b2f30FbDeC90e1cdc25f",
  hyperevm: "0xd83EDb24948eEfAF30d9b2f30FbDeC90e1cdc25f",
};

const SolvBTCYieldTokenV3BeaconAddresses = {
  dev_sepolia: "0x0C62BEc3Ef44cD5d6b795B37F986Bee6B7Ca9550",
  sepolia: "0x5409D9f1516fFc65DDe006Bf28c3c7Ca642aa71b",
  ink_test: "0x25883B7Aea8775C32699A01D7edaE557219E03d3",
  hyperevm_test: "0x25883B7Aea8775C32699A01D7edaE557219E03d3",
  mainnet: "0x27F2328aFeF3af851753E3Eca5E7d2281c3C22F6",
  bsc: "",
  avax: "0xFE2E0c4249DCB69F219dd2BE918EB1cef9E5dAf2",
  bob: "",
  soneium: "0x11d174BF28F2E71B7c1FCB157096e44E74bA8585",
  polygon: "0xFE2E0c4249DCB69F219dd2BE918EB1cef9E5dAf2",
  ink: "0xFE2E0c4249DCB69F219dd2BE918EB1cef9E5dAf2",
  hyperevm: "0xFE2E0c4249DCB69F219dd2BE918EB1cef9E5dAf2",
};

const SolvBTCYieldTokenInfos = {
  mainnet: {
    "SolvBTC DEX LP": {  // id = 343
      erc20: "0x32Bc653dbD08C70f4dDEF2Bab15915193A617D75",
      sft: "0x982D50f8557D57B748733a3fC3d55AeF40C46756",
      slot: "17660905005845915868798550309913569450157209061885611613682651900123401414530",
      poolId: "0xa11f08f40185c0ba7ff7f5ea343798a4e2cd0f0d65d47fd5a59ebb51d2d275fa",
      navOracle: "0x8c29858319614380024093dbee553f9337665756",
      holdingValueSftId: 0,
    },
  },
  bsc: {
    "SolvBTC Bera Vault": {  // id = 352
      erc20: "",
      sft: "0xB816018E5d421E8b809A4dc01aF179D86056eBDF",
      slot: "70222896071207762779953378931956679402408390821663654047017958775368527671200",
      poolId: "0x0b2bb30466fb1d5b0c664f9a6e4e1a90d5c8bc5abaecd823563641d6fc5ae57a",
      navOracle: "0x9C491539AeC346AAFeb0bee9a1e9D9c02AB50889",
      holdingValueSftId: 0,
    },
  },
  avax: {
    "SolvBTC Avalanche": {  // id = 344
      erc20: "0x6C7d727a0432D03351678F91FAA1126a5B871DF5",
      sft: "0x29F870Ed75B4632301946bB935433605f39d515E",
      slot: "86753098298693272234281896498673541742160926213380072723269693569823891599359",
      poolId: "0x83933f7cabce9efa8ed17c7f601dba81cfa49f0dabaf2885bf1624719bf78443",
      navOracle: "0x540a9DBBA1AE6250253ba8793714492ee357ac1D",
      holdingValueSftId: 0,
    },
  },
  bob: {
    "SolvBTC Bera Vault": {  // id = 353
      erc20: "",
      sft: "0x29F870Ed75B4632301946bB935433605f39d515E",
      slot: "55617451925192291987943078869523025238057240556376942035959585371788117273753",
      poolId: "0xdecbbc2d7327df6a7123775568b05eb192cc30c3156fe875698689d70dbc7d2c",
      navOracle: "0x1210371F2E26a74827F250afDfdbE3091304a3b7",
      holdingValueSftId: 0,
    },
  },
  polygon: {
    "xSolvBTC": {
      erc20: "0xc99F5c922DAE05B6e2ff83463ce705eF7C91F077",
      sft: "",
      slot: "",
      poolId: "",
      navOracle: "",
      holdingValueSftId: 0,
    },
  },
  ink: {
    "xSolvBTC": {
      erc20: "0xc99F5c922DAE05B6e2ff83463ce705eF7C91F077",
      sft: "0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe",
      slot: "21878350592799687335720143765034541687231338182764106208669036308924224432770",
      poolId: "0xeb419d20c80a32da9ba3b4dd8aa799fd3bc605d0739aa545775d89d9f7767642",
      navOracle: "0x600Fb9600444fb8373bF9A112Ae0977F6676c564",
      holdingValueSftId: 0,
    },
  },
  hyperevm: {
    "xSolvBTC": {
      erc20: "0xc99F5c922DAE05B6e2ff83463ce705eF7C91F077",
      sft: "",
      slot: "",
      poolId: "",
      navOracle: "",
      holdingValueSftId: 0,
    },
  },
};

module.exports = {
  SolvBTCYieldTokenFactoryV3Addresses,
  SolvBTCYieldTokenV3BeaconAddresses,
  SolvBTCYieldTokenInfos,
};
