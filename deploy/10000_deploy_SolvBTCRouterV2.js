const transparentUpgrade = require("./utils/transparentUpgrade");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const owner = deployer;

  const market = {
    dev_sepolia: "0x109198Eb8BD3064Efa5d0711b505f59cFd77de18",
    sepolia: "0x91967806F47e2c6603C9617efd5cc91Bc2A7473E",
    bsctest: "0x929b1B405714ef93CdFFFd6492009baff351f788",
    mainnet: "0x57bB6a8563a8e8478391C79F3F433C6BA077c567",
    bsc: "0xaE050694c137aD777611286C316E5FDda58242F3",
    avax: "0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf",
    bob: "0xf5a247157656678398B08d3eFa1673358C611A3f",
    bera: "0x56a4d805d7A292f03Ead5Be31E0fFB8f7d0E3B48",
    hyperevm: "0x48780A97Cd325B8E03661F17a848159e14aaec8D",
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
        "0xe96aa35e6c50231467ae2d976068203e84c941f75607ccc7e86812fc302e7c5b", // pool ID
      ],
      [
        "0x7157D9B6bEF77BDC9e8162659239252DD9FB875C", // target token - SolvBTC.BNB
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", // currency - SolvBTC
        "0x99c41e9ff1f784188aed35e866b6888c11593ea6b61db4ae721f699ca316c463", // pool ID
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
      [
        "0x32Bc653dbD08C70f4dDEF2Bab15915193A617D75", // target token - SolvBTC.DLP
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // currency - SolvBTC
        "0xa11f08f40185c0ba7ff7f5ea343798a4e2cd0f0d65d47fd5a59ebb51d2d275fa", // pool ID
      ],
    ],
    bsc: [
      [
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // target token - SolvBTC
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0xafb1107b43875eb79f72e3e896933d4f96707451c3d5c32741e8e05410b321d8", // 102 fund pool ID
      ],
      [
        "0x1346b618dC92810EC74163e4c27004c921D446a5", // target token - xSolvBTC
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x6fe7f2753798616f555389f971dae58b32e181fab8b1d60d35e5ddafbb6bb5b7", // 103 fund pool ID
      ],
      [
        "0x647A50540F5a1058B206f5a3eB17f56f29127F53", // target token - SolvBTC.DeFi
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x34bba90734634811d28d6c33eaad61f93686793ddf442190573619e9476c8925", // 240 fund pool ID
      ],
      [
        "0x6c948A4C31D013515d871930Fe3807276102F25d", // target token - SolvBTC.BNB
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x02228958e4f53e94e09cc0afd49939bf93af0b991889fa5fe761672c0e9c3021", // 340 fund pool ID
      ],
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        "0x1346b618dC92810EC74163e4c27004c921D446a5", // currency - xSolvBTC
        "0x0b2bb30466fb1d5b0c664f9a6e4e1a90d5c8bc5abaecd823563641d6fc5ae57a", // 352 fund pool ID
      ],
    ],
    avax: [
      [
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", // target token - SolvBTC
        "0x152b9d0FdC40C096757F570A51E494bd4b943E50", // currency - BTC.b
        "0xf5ae38da3319d22b4628e635f6fa60bf966de13c5334b6845eba764d6321e16b", // 183 fund pool ID
      ],
      [
        "0x6C7d727a0432D03351678F91FAA1126a5B871DF5", // target token - SolvBTC.AVAX
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", // currency - SolvBTC
        "0x83933f7cabce9efa8ed17c7f601dba81cfa49f0dabaf2885bf1624719bf78443", // 344 fund pool ID
      ],
    ],
    bob: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // target token - SolvBTC
        "0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3", // currency - WBTC
        "0x5664520240a46b4b3e9655c20cc3f9e08496a9b746a478e476ae3e04d6c8fc31", // 197 fund pool ID
      ],
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // target token - xSolvBTC
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x6899a7e13b655fa367208cb27c6eaa2410370d1565dc1f5f11853a1e8cbef033", // 198 fund pool ID
      ],
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // currency - xSolvBTC
        "0xdecbbc2d7327df6a7123775568b05eb192cc30c3156fe875698689d70dbc7d2c", // 353 fund pool ID
      ],
    ],
    bera: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // target token - SolvBTC
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c", // currency - WBTC
        "0x8d0d551de285206573e1ff69a95bc8a9624c77d47f41a37a1f245c3cf4bc0d6b", // 354 fund pool ID
      ],
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // target token - xSolvBTC
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x2716ab5b436a50e2a32950745dd1984909642afd749bb216709dfc2a993d11ca", // 355 fund pool ID
      ],
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // currency - xSolvBTC
        "0x2bfddb460b2050c9e7567eec1f3ac39c1766a404299038080a4ad7ec294b6425", // 356 fund pool ID
      ],
    ],
    hyperevm: [
      [
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", // target token - SolvBTC
        "0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463", // currency - UBTC
        "0x8f7c9f7133da42e0610c8e4ac4cd06d183c8315b8c68632d5ca825eab62b1d51", // 360 fund pool ID
      ],
      [
        "0xc99F5c922DAE05B6e2ff83463ce705eF7C91F077", // target token - xSolvBTC
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", // currency - SolvBTC
        "0x20ab0178dcd647ef0d88df3daa2453e1677b2360cd4f6f98bb4603d7b9b7303a", // 361 fund pool ID
      ],
      [
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F", // target token - SolvBTC.BNB
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", // currency - SolvBTC
        "0xa055402e0286dee50dd8e31a2fc495fe64e0035edf83bc4dd3477bacb6339d20", // 362 fund pool ID
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
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x7157D9B6bEF77BDC9e8162659239252DD9FB875C", // target token - SolvBTC.BNB
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
      [
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // currency - WBTC
        "0x32Bc653dbD08C70f4dDEF2Bab15915193A617D75", // target token - SolvBTC.DLP
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: WBTC -> SolvBTC -> SolvBTC.DLP
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
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x6c948A4C31D013515d871930Fe3807276102F25d", // target token - SolvBTC.BNB
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path - SolvBTC
      ],
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", "0x1346b618dC92810EC74163e4c27004c921D446a5"], // path: BTCB -> SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0x1346b618dC92810EC74163e4c27004c921D446a5"], // path: SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
    ],
    avax: [
      [
        "0x152b9d0FdC40C096757F570A51E494bd4b943E50", // currency - BTC.b
        "0x6C7d727a0432D03351678F91FAA1126a5B871DF5", // target token - SolvBTC.AVAX
        ["0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777"], // path - SolvBTC
      ],
    ],
    bob: [
      [
        "0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3", // currency - WBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", "0xCC0966D8418d412c599A6421b760a847eB169A8c"], // path: BTCB -> SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0xCC0966D8418d412c599A6421b760a847eB169A8c"], // path: SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
    ],
    bera: [
      [
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c", // currency - WBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", "0xCC0966D8418d412c599A6421b760a847eB169A8c"], // path: BTCB -> SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0xCC0966D8418d412c599A6421b760a847eB169A8c"], // path: SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
    ],
    hyperevm: [
      [
        "0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463", // currency - UBTC
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F", // target token - SolvBTC.BNB
        ["0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3"], // path: UBTC -> SolvBTC -> SolvBTC.BNB
      ],
    ],
  };

  const multiAssetPools = {
    dev_sepolia: [
      [ "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", "0xBdF15396e8A49773386fBA396D74dbbB8ED993f2" ], // SolvBTC
      [ "0x49aFCf847193c48091969bdB20852ef4c5A534D7", "0xc57C23278e0C02998bbA7D5a842A49F34744d4ce" ], // SolvBTC.BERA
      [ "0x7157D9B6bEF77BDC9e8162659239252DD9FB875C", "0xc57C23278e0C02998bbA7D5a842A49F34744d4ce" ], // SolvBTC.BNB
    ],
    sepolia: [
      [ "0xE33109766662932a26d978123383ff9E7bdeF346", "0xeC8A36eF9b006abf8c477bD82c649067DB2A3769" ], // SolvBTC
      [ "0x96231D57c60C0d64d14F080d771a98FDaDD2Ec8A", "0x58D91F2A23ddB50Cc699424e9E74097A51509b7c" ], // SolvBTC.YP
      [ "0xf44c01111C54C550d044025099220D79B9559EB9", "0x58D91F2A23ddB50Cc699424e9E74097A51509b7c" ], // SolvBTC.BBN
      [ "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0", "0x58D91F2A23ddB50Cc699424e9E74097A51509b7c" ], // SolvBTC.BERA
    ],
    bsctest: [
      [ "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", "0xED714AC014a11e758af1Fbc53d3B8a6F3056a1F8" ], // SolvBTC
      [ "0xB4618618b6Fcb61b72feD991AdcC344f43EE57Ad", "0x56006176aEe38928ea658A80De972E9232521026" ], // SolvBTC.BBN
      [ "0x89E573571B6786b11643585acbCcF3Cb3ABef81e", "0x56006176aEe38928ea658A80De972E9232521026" ], // SolvBTC.DeFi
    ],
    mainnet: [
      [ "0x7A56E1C57C7475CCf742a1832B028F0456652F97", "0x1d5262919C4AAb745A8C9dD56B80DB9FeaEf86BA" ], // SolvBTC
      [ "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", "0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D" ], // SolvBTC.BBN
      [ "0xE7C253EAD50976Caf7b0C2cbca569146A7741B50", "0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D" ], // SolvBTC.BERA
      [ "0x32Bc653dbD08C70f4dDEF2Bab15915193A617D75", "0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D" ], // SolvBTC.DLP
    ],
    bsc: [
      [ "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", "0x1FF72318deeD339e724e3c8deBCD528dC013D845" ], // SolvBTC
      [ "0x1346b618dC92810EC74163e4c27004c921D446a5", "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A" ], // SolvBTC.BBN
      [ "0x647A50540F5a1058B206f5a3eB17f56f29127F53", "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A" ], // SolvBTC.DeFi
      [ "0x6c948A4C31D013515d871930Fe3807276102F25d", "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A" ], // SolvBTC.BNB
      [ "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A" ], // SolvBTC.BERA
    ],
    avax: [
      [ "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", "0x0BA5f53a4Bf22C9e5947aeb6eA4521D030f35705" ], // SolvBTC
      [ "0x6C7d727a0432D03351678F91FAA1126a5B871DF5", "0x814F3ae67dF0da9fe2399a29516FD14b9085263a" ], // SolvBTC.AVAX
    ],
    bob: [
      [ "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", "0xc2f69541e3dC306777D260dC66bfD54fcb897100" ], // SolvBTC
      [ "0xCC0966D8418d412c599A6421b760a847eB169A8c", "0xd157B70F917fEf3A59502b9128feCA911dEbC864" ], // xSolvBTC
      [ "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", "0xd157B70F917fEf3A59502b9128feCA911dEbC864" ], // SolvBTC.BERA
    ],
    bera: [
      [ "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", "0xf4F39602D0a6C8f60C23208819140F2C3FA1662C" ], // SolvBTC
      [ "0xCC0966D8418d412c599A6421b760a847eB169A8c", "0xeC34989BECD59158f3B1A5cdfFDb667fa2e4d957" ], // xSolvBTC
      [ "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", "0xeC34989BECD59158f3B1A5cdfFDb667fa2e4d957" ], // SolvBTC.BERA
    ],
    hyperevm: [
      [ "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", "0x45fb21ac62503c0Bb6FfF3513a3D0fFAAA11aCDb" ], // SolvBTC
      [ "0xc99F5c922DAE05B6e2ff83463ce705eF7C91F077", "0x2DC5392c35e6682ed27EDE187AC159BA020a5eda" ], // xSolvBTC
      [ "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F", "0x2DC5392c35e6682ed27EDE187AC159BA020a5eda" ], // SolvBTC.BNB
    ],
  };

  const contractName = "SolvBTCRouterV2";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {
    dev_sepolia: ["v2.1"],
    sepolia: ["v2.1"],
    bsctest: ["v2.1"],
    mainnet: ["v2.1"],
    bsc: ["v2.1"],
  };
  const upgrades = versions[network.name]?.map((v) => {return firstImplName + "_" + v;}) || [];

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

  const SolvBTCRouterV2Factory = await ethers.getContractFactory("SolvBTCRouterV2", deployer);
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(proxy.address);

  const currentMarket = await solvBTCRouterV2.openFundMarket();
  if (currentMarket.toLowerCase() != market[network.name].toLowerCase()) {
    let setMarketTx = await solvBTCRouterV2.setOpenFundMarket(market[network.name]);
    console.log(`Set OpenFundMarket ${market[network.name]} at tx: ${setMarketTx.hash}`);
    await setMarketTx.wait(1);
  }

  for (let poolId of poolIds[network.name]) {
    let currentPoolId = await solvBTCRouterV2.poolIds(poolId[0], poolId[1]);
    if (currentPoolId != poolId[2]) {
      let setPoolIdTx = await solvBTCRouterV2.setPoolId(poolId[0], poolId[1], poolId[2]);
      console.log(`Set PoolInfo for poolId ${poolId[2]} at tx: ${setPoolIdTx.hash}`);
      await setPoolIdTx.wait(1);
    }
  }

  for (let pathInfo of pathInfos[network.name]) {
    try {
      let currentPath = await solvBTCRouterV2.paths(pathInfo[0], pathInfo[1], 0);
      if (currentPath.toLowerCase() != pathInfo[2][0].toLowerCase()) {
        throw new Error("Path not match");
      }
    } catch (e) {
      let setPathTx = await solvBTCRouterV2.setPath(pathInfo[0], pathInfo[1], pathInfo[2]);
      console.log(`Set Path for {${pathInfo[0]} ${pathInfo[1]}} at tx: ${setPathTx.hash}`);
      await setPathTx.wait(1);
    }
  }

  for (let multiAssetPool of multiAssetPools[network.name]) {
    let currentPool = await solvBTCRouterV2.multiAssetPools(multiAssetPool[0]);
    if (currentPool != multiAssetPool[1]) {
      let setPoolTx = await solvBTCRouterV2.setMultiAssetPool(multiAssetPool[0], multiAssetPool[1]);
      console.log(`Set MultiAssetPool for token ${multiAssetPool[0]} at tx: ${setPoolTx.hash}`);
      await setPoolTx.wait(1);
    }
  }

};

module.exports.tags = ["SolvBTCRouterV2"];
