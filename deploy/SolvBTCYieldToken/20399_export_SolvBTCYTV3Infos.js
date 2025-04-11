const SolvBTCYieldTokenFactoryV3Addresses = {
  dev_sepolia: "0x197cfd48184ADCCa3b061851118c624c22EE59b2",
  sepolia: "0x197cfd48184ADCCa3b061851118c624c22EE59b2",
  mainnet: "0x86fC77cfe9F7d6a84097E9B73bd32cA185fdb12a",
  avax: "0xd83EDb24948eEfAF30d9b2f30FbDeC90e1cdc25f",
  soneium: "0xF233c5cac3177c70a554C0178cFA85f61D97622B",
  polygon: "0xd83EDb24948eEfAF30d9b2f30FbDeC90e1cdc25f",
};

const SolvBTCYieldTokenV3BeaconAddresses = {
  dev_sepolia: "0x0C62BEc3Ef44cD5d6b795B37F986Bee6B7Ca9550",
  sepolia: "0x5409D9f1516fFc65DDe006Bf28c3c7Ca642aa71b",
  mainnet: "0x27F2328aFeF3af851753E3Eca5E7d2281c3C22F6",
  avax: "0xFE2E0c4249DCB69F219dd2BE918EB1cef9E5dAf2",
  soneium: "0x11d174BF28F2E71B7c1FCB157096e44E74bA8585",
  polygon: "0xFE2E0c4249DCB69F219dd2BE918EB1cef9E5dAf2",
};

const SolvBTCYieldTokenInfos = {
  mainnet: {
    "SolvBTC DEX LP": {
      // https://fund-management.solv.finance/open-fund/management/343/overview
      erc20: "0x32Bc653dbD08C70f4dDEF2Bab15915193A617D75",
      sft: "0x982D50f8557D57B748733a3fC3d55AeF40C46756",
      slot: "17660905005845915868798550309913569450157209061885611613682651900123401414530",
      poolId: "0xa11f08f40185c0ba7ff7f5ea343798a4e2cd0f0d65d47fd5a59ebb51d2d275fa",
      navOracle: "0x8c29858319614380024093dbee553f9337665756",
      holdingValueSftId: 0,
    },
  },
  avax: {
    "SolvBTC Avalanche": {
      // https://fund-management.solv.finance/open-fund/management/344/overview
      erc20: "0x6C7d727a0432D03351678F91FAA1126a5B871DF5",
      sft: "0x29F870Ed75B4632301946bB935433605f39d515E",
      slot: "86753098298693272234281896498673541742160926213380072723269693569823891599359",
      poolId: "0x83933f7cabce9efa8ed17c7f601dba81cfa49f0dabaf2885bf1624719bf78443",
      navOracle: "0x540a9DBBA1AE6250253ba8793714492ee357ac1D",
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
};

module.exports = {
  SolvBTCYieldTokenFactoryV3Addresses,
  SolvBTCYieldTokenV3BeaconAddresses,
  SolvBTCYieldTokenInfos,
};
