const SolvBTCYieldTokenFactoryAddresses = {
  zksyncSepolia: "0xc7E3C96dE540449959110b68B8769c717491Cc72",
  zkSyncMainnet: "0xCDa284619c6A22119e77bD4198a7A28892897aDd",
};

const SolvBTCYieldTokenBeaconAddresses = {
  zksyncSepolia: "0xCc7Af3fbF3f05A4a94781872AcC14e85838387b4",
  zkSyncMainnet: "0x3091A98aeF0004A33554DC082167C8f2a62E8F22",
};

const SolvBTCYieldTokenMultiAssetPoolAddresses = {
  zksyncSepolia: "0xCAb15Ed3d8784a633A6b452e50556c18b0753c1a",
  zkSyncMainnet: "0x75BC093342039b5F21569a640C907e18693699C1",
};

const SolvBTCYieldTokenInfos = {
  zksyncSepolia: {
    "SolvBTC Yield Pool (BBN)": {
      erc20: "0x678ab7961c31beB87e776eD799d13F22985ebF1B",
      sft: "",
      slot: "",
      poolId: "",
      navOracle: "",
      holdingValueSftId: 0,
    },
  },
  zkSyncMainnet: {
    "SolvBTC Babylon": {
      erc20: "0x2878295D69Aa3BDcf9004FCf362F0959992D801c",
      sft: "",
      slot: "",
      poolId: "",
      navOracle: "",
      holdingValueSftId: 0,
    }
  }
};

module.exports = {
  SolvBTCYieldTokenFactoryAddresses,
  SolvBTCYieldTokenBeaconAddresses,
  SolvBTCYieldTokenMultiAssetPoolAddresses,
  SolvBTCYieldTokenInfos,
};
