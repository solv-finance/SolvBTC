const colors = require("colors");
const { txWait } = require("../utils/deployUtils");
const assert = require("assert");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  
  const fofNavOracleAbi = [
    "function setSubscribeNavOnlyAdmin(bytes32 fofPoolId, uint256 nav)",
    "function getSubscribeNav(bytes32 fofPoolId, uint256 time) view returns (uint256 nav, uint256 navTime)",
    "function admin() view returns (address)",
  ];

  const fofNavOracleAddresses = {
    mainnet: "0xf940230a3357971fe0F22E8C144BC70d9fA91d43",
    bsc: "0xBfda88765A07F60b04619D1C95a3eC1E75f8B71E",
    arb: "0xc09022C379eE2bee0Da72813C0C84c3Ed8521251",
    base: "0x8B79e5bF5689C38A9fC386AfdFb1a12b1aBDeb0b",
    ink: "0x2a83BF5866FBC782B71f859589a4D28b55190949",
  };
  const fofNavOracle = await ethers.getContractAt(fofNavOracleAbi, fofNavOracleAddresses[network.name]);

  const poolNavs = {
    mainnet: [
      ["0x2dc130e46b5958208155546bd4049d5b3319798063a8c4180b4b2b82f3ebdc3d", 100000000n],
      ["0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307", 100000000n],
      ["0xdc0937dd33c4af08a08724da23bc45b33b43fbb23f365e7b50a536ce45f447ef", 100000000n],
      ["0x23299b545056e9846725f89513e5d7f65a5034ab36515287ff8a27e860b1be75", 1000000000000000000n],
    ],
    bsc: [
      ["0xafb1107b43875eb79f72e3e896933d4f96707451c3d5c32741e8e05410b321d8", 1000000000000000000n],
    ],
    arb: [
      ["0x488def4a346b409d5d57985a160cd216d29d4f555e1b716df4e04e2374d2d9f6", 100000000n],
    ],
    base: [
      ["0x0d85d41382f6f2effeaa41a46855870ec8b1577c6c59cf16d72856a22988e3f5", 100000000n],
      ["0x1706a4881586917b18c2274dfdbcdffe48ee22e18c99090dcee7dd38464526b4", 1000000000000000000n],
    ],
    ink: [
      ["0x49c5914da51b1db7b098590c27d19e6ef45e7edcbe37f6854a03bc73afee6b7a", 100000000n],
    ],
  };

  for (const [poolId, nav] of poolNavs[network.name]) {
    const currentNavInfo = await fofNavOracle.getSubscribeNav(poolId, 1);
    console.log(`poolId ${poolId} current nav: ${currentNavInfo[0]}`);
    if (nav == currentNavInfo[0]) {
      console.log(`  - same nav, ignore`.green);
    } else {
      console.log(`  - setting nav to ${nav}`.yellow);
      const tx = await fofNavOracle.setSubscribeNavOnlyAdmin(poolId, nav);
      console.log(`  - tx hash: ${tx.hash}`);
      await txWait(tx);
    }
  }
};

module.exports.tags = ["SetFoFNav"];
