const transparentUpgrade = require("./utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const owner = deployer;

  const market = {
    dev_sepolia: "0x109198Eb8BD3064Efa5d0711b505f59cFd77de18",
    sepolia: "0x91967806F47e2c6603C9617efd5cc91Bc2A7473E",
    bsctest: "0x929b1B405714ef93CdFFFd6492009baff351f788",
    bsc: "0xaE050694c137aD777611286C316E5FDda58242F3",
    mainnet: "0x57bB6a8563a8e8478391C79F3F433C6BA077c567",
  };

  // target token, currency, poolId
  const poolIds = {
    dev_sepolia: [
      [
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", // target token - SolvBTC
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x5f3b1c93ef16dcf5a6186a5930bef5424f4e9fc7ffeeb426197553372f3a1e7f", // pool ID
      ],
      [
        "0x49aFCf847193c48091969bdB20852ef4c5A534D7", // target token - SolvBTC.BERA
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", // currency - SolvBTC
        "0x29c9b799129420fe495748aa21383cd8447ec27ec37d1baa3b105a38a869c9e0", // pool ID
      ],
    ],
    sepolia: [
      [
        "0xE33109766662932a26d978123383ff9E7bdeF346", // target token - SolvBTC
        "0x7A9689202fddE4C2091B480c70513184b2F8555C", // currency - WBTC
        "0x333be9604463a7be6dd9bb5b05b03b53faf112b8eb016f844f301fc9944b598b", // pool ID
      ],
      [
        "0xE33109766662932a26d978123383ff9E7bdeF346", // target token - SolvBTC
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x21c6ca98740d2bcda57f1fe2089df30a85090953b4ab33ebcd16da8e9a681d5d", // pool ID
      ],
      [
        "0xf44c01111C54C550d044025099220D79B9559EB9", // target token - SolvBTC.BBN
        "0xE33109766662932a26d978123383ff9E7bdeF346", // currency - SolvBTC
        "0x64a66ad214a02b4136f8ab710e690b31fdbf359c82ecc7814034a5b60287968b", // pool ID
      ],
      [
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0", // target token - SolvBTC.BERA
        "0xf44c01111C54C550d044025099220D79B9559EB9", // currency - SolvBTC.BBN
        "0xcc9d13a3a88543ca12b37f4d9592f3a3dd62ae17dee34bf82e4eb6cb0f4a2ce2", // pool ID
      ],
    ],
    bsctest: [
      [
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // target token - SolvBTC
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E", // currency - BTCB
        "0x9f4baed29e08317798d7d50e376733dac70eb6819ab6a843029c138f06cea479", // pool ID
      ],
      [
        "0xB4618618b6Fcb61b72feD991AdcC344f43EE57Ad", // target token - SolvBTC.BBN
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xaf3b2b789b70339ac56f23c2c8bfd0edd2b1b496f174aefa46880e011fc86187", // pool ID
      ],
      [
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c", // target token - SolvBTC.ENA
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xc0aefb6754da0510f31decd714b5b3f349b4bf1875c1ab6ddafedba6f33d3e72", // pool ID
      ],
      [
        "0x89E573571B6786b11643585acbCcF3Cb3ABef81e", // target token - SolvBTC.DEFI
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xde178805efb7fbbf779048a5a09fb176f7c28fb87204718fcc9c6f927eea8140", // pool ID
      ],
    ],
    mainnet: [
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // target token - SolvBTC
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // currency - WBTC
        "0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307", // pool ID
      ],
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // target token - SolvBTC
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0xdc0937dd33c4af08a08724da23bc45b33b43fbb23f365e7b50a536ce45f447ef", // pool ID
      ],
      [
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // target token - SolvBTC.BBN
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // currency - SolvBTC
        "0xefcca1eb946cdc7b56509489a56b45b75aff74b8bb84dad5b893012157e0df93", // pool ID
      ],
      [
        "0xE7C253EAD50976Caf7b0C2cbca569146A7741B50", // target token - SolvBTC.BERA
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // currency - SolvBTC.BBN
        "0xc63f3d6660f19445e108061adf74e0471a51a33dad30fe9b4815140168fd6136", // pool ID
      ],
    ],
    bsc: [
      [
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // target token - SolvBTC
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0xafb1107b43875eb79f72e3e896933d4f96707451c3d5c32741e8e05410b321d8", // 102 fund pool ID
      ],
      [
        "0x1346b618dC92810EC74163e4c27004c921D446a5", // target token - SolvBTC.BBN
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x6fe7f2753798616f555389f971dae58b32e181fab8b1d60d35e5ddafbb6bb5b7", // 103 fund pool ID
      ],
      [
        "0x647A50540F5a1058B206f5a3eB17f56f29127F53", // target token - SolvBTC.DeFi
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x34bba90734634811d28d6c33eaad61f93686793ddf442190573619e9476c8925", // 240 fund pool ID
      ],
    ],
  };

  // currency, target token, path
  const pathInfos = {
    dev_sepolia: [
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x49aFCf847193c48091969bdB20852ef4c5A534D7", // target token - SolvBTC.BERA
        ["0xe8C3edB09D1d155292BE0453d57bC3250a0084B6"], // path
      ],
    ],
    sepolia: [
      [
        "0x7A9689202fddE4C2091B480c70513184b2F8555C", // currency - WBTC
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0", // target token - SolvBTC.BERA
        [
          "0xE33109766662932a26d978123383ff9E7bdeF346",
          "0xf44c01111C54C550d044025099220D79B9559EB9",
        ], // path: WBTC -> SolvBTC -> SolvBTC.BBN -> SolvBTC.BERA
      ],
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0", // target token - SolvBTC.BERA
        [
          "0xE33109766662932a26d978123383ff9E7bdeF346",
          "0xf44c01111C54C550d044025099220D79B9559EB9",
        ], // path: SBTC -> SolvBTC -> SolvBTC.BBN -> SolvBTC.BERA
      ],
      [
        "0xE33109766662932a26d978123383ff9E7bdeF346", // currency - SolvBTC
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0", // target token - SolvBTC.BERA
        ["0xf44c01111C54C550d044025099220D79B9559EB9"], // path: SolvBTC -> SolvBTC.BBN -> SolvBTC.BERA
      ],
    ],
    bsctest: [
      [
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E", // currency - BTCB
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c", // target token - SolvBTC.ENA
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
      [
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E", // currency - BTCB
        "0x89E573571B6786b11643585acbCcF3Cb3ABef81e", // target token - SolvBTC.DEFI
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
    ],
    mainnet: [
      [
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // currency - WBTC
        "0xE7C253EAD50976Caf7b0C2cbca569146A7741B50", // target token - SolvBTC.BERA
        [
          "0x7A56E1C57C7475CCf742a1832B028F0456652F97",
          "0xd9D920AA40f578ab794426F5C90F6C731D159DEf",
        ], // path: WBTC -> SolvBTC -> SolvBTC.BBN -> SolvBTC.BERA
      ],
      [
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0xE7C253EAD50976Caf7b0C2cbca569146A7741B50", // target token - SolvBTC.BERA
        [
          "0x7A56E1C57C7475CCf742a1832B028F0456652F97",
          "0xd9D920AA40f578ab794426F5C90F6C731D159DEf",
        ], // path: cbBTC -> SolvBTC -> SolvBTC.BBN -> SolvBTC.BERA
      ],
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // currency - SolvBTC
        "0xE7C253EAD50976Caf7b0C2cbca569146A7741B50", // target token - SolvBTC.BERA
        ["0xd9D920AA40f578ab794426F5C90F6C731D159DEf"], // path: SolvBTC -> SolvBTC.BBN -> SolvBTC.BERA
      ],
    ],
    bsc: [
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x1346b618dC92810EC74163e4c27004c921D446a5", // target token - SolvBTC.BBN
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path - SolvBTC
      ],
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x647A50540F5a1058B206f5a3eB17f56f29127F53", // target token - SolvBTC.DeFi
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path - SolvBTC
      ],
    ],
  };

  const contractName = "SolvBTCRouterV2";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {};
  const upgrades =
    versions[network.name]?.map((v) => {
      return firstImplName + "_" + v;
    }) || [];

  const { proxy, newImpl, newImplName } =
    await transparentUpgrade.deployOrUpgrade(
      firstImplName,
      proxyName,
      {
        contract: contractName,
        from: deployer,
        log: true,
      },
      {
        initializer: {
          method: "initialize",
          args: [owner],
        },
        upgrades: upgrades,
      }
    );

  const SolvBTCRouterV2Factory = await ethers.getContractFactory(
    "SolvBTCRouterV2",
    deployer
  );
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(proxy.address);

  const currentMarket = await solvBTCRouterV2.openFundMarket();
  if (currentMarket.toLowerCase() != market[network.name].toLowerCase()) {
    let setMarketTx = await solvBTCRouterV2.setOpenFundMarket(
      market[network.name]
    );
    console.log(
      `Set OpenFundMarket ${market[network.name]} at tx: ${setMarketTx.hash}`
    );
    await setMarketTx.wait(1);
  }

  for (let poolId of poolIds[network.name]) {
    let currentPoolId = await solvBTCRouterV2.poolIds(poolId[0], poolId[1]);
    if (currentPoolId != poolId[2]) {
      let setPoolIdTx = await solvBTCRouterV2.setPoolId(
        poolId[0],
        poolId[1],
        poolId[2]
      );
      console.log(
        `Set PoolInfo for poolId ${poolId[2]} at tx: ${setPoolIdTx.hash}`
      );
      await setPoolIdTx.wait(1);
    }
  }

  for (let pathInfo of pathInfos[network.name]) {
    try {
      let currentPath = await solvBTCRouterV2.paths(
        pathInfo[0],
        pathInfo[1],
        0
      );
      if (currentPath.toLowerCase() != pathInfo[2][0].toLowerCase()) {
        throw new Error("Path not match");
      }
    } catch (e) {
      let setPathTx = await solvBTCRouterV2.setPath(
        pathInfo[0],
        pathInfo[1],
        pathInfo[2]
      );
      console.log(
        `Set Path for {${pathInfo[0]} ${pathInfo[1]}} at tx: ${setPathTx.hash}`
      );
      await setPathTx.wait(1);
    }
  }
};

module.exports.tags = ["SolvBTCRouterV2"];
