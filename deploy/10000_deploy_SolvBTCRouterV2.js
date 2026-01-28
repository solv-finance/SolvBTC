const transparentUpgrade = require("./utils/transparentUpgrade");
const { txWait } = require("./utils/deployUtils");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();
  const owner = deployer;

  const market = {
    dev_sepolia: "0x109198Eb8BD3064Efa5d0711b505f59cFd77de18",
    sepolia: "0x91967806F47e2c6603C9617efd5cc91Bc2A7473E",
    bsctest: "0x929b1B405714ef93CdFFFd6492009baff351f788",
    avax_test: "0xb873927Db3145BdDf1F63acE301CD6eCe52cC4bD",
    mainnet: "0x57bB6a8563a8e8478391C79F3F433C6BA077c567",
    bsc: "0xaE050694c137aD777611286C316E5FDda58242F3",
    mantle: "0x1210371F2E26a74827F250afDfdbE3091304a3b7",
    avax: "0x59Cf3db95bdF5C545877871c3863c9DBe6b0b7cf",
    arb: "0x629aD7Bc14726e9cEA4FCb3A7b363D237bB5dBE8",
    base: "0xf5a247157656678398B08d3eFa1673358C611A3f",
    bob: "0xf5a247157656678398B08d3eFa1673358C611A3f",
    bera: "0x56a4d805d7A292f03Ead5Be31E0fFB8f7d0E3B48",
    hyperevm: "0x48780A97Cd325B8E03661F17a848159e14aaec8D",
    base: "0xf5a247157656678398B08d3eFa1673358C611A3f",
    rootstock: "0x6c8dA184B019E6C4Baa710113c0d9DE68A693B1f",
    ink: "0xBa891CE042BdB092C450D242c05DB44d7e5Bb728",
    xlayer: "",
  };

  // target token, currency, poolId
  const poolIds = {
    dev_sepolia: [
      [
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", // target token - SolvBTC
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x5f3b1c93ef16dcf5a6186a5930bef5424f4e9fc7ffeeb426197553372f3a1e7f", // 154 pool ID
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
      [
        "0x3acF2f3C24717113fB72da17565B3acacabA8595", // target token - SolvBTC.TRADING
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", // currency - SolvBTC
        "0x4fade1ad2f41383400b5c0bc6d9c863644bcbbb16a407fb9a0d043f7578b00c5", // 163 pool ID
      ],
      [
        "0xBfE4B499B55084da6a0dA89E0254893B241Dca18", // target token - BTC+
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6", // currency - SolvBTC
        "0x1192db2ccd7787d7d2fd5576ac6c900b1401127de3d44c237470a4fb5ed57ced", // 257 pool ID
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
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
      ],
      [
        "0x96231D57c60C0d64d14F080d771a98FDaDD2Ec8A", // target token - SolvBTC.TRADING
        "0xE33109766662932a26d978123383ff9E7bdeF346", // currency - SolvBTC
        "0xf82ad2ca2bab8adcf837b1f57b7aa204e479ba03b43aacf585c5ce770158ab39", // 73 pool ID
      ],
      [
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0", // target token - SolvBTC.BERA
        "0xf44c01111C54C550d044025099220D79B9559EB9", // currency - SolvBTC.BBN
        "0xcc9d13a3a88543ca12b37f4d9592f3a3dd62ae17dee34bf82e4eb6cb0f4a2ce2", // pool ID
      ],
      [
        "0x72B6573FCB8d54522C28689e0aA0B6C77fD245ed", // target token - BTC+
        "0xE33109766662932a26d978123383ff9E7bdeF346", // currency - SolvBTC
        "0x89e41449586939cca9764b57d5f82c9a12f7420775459bbc7b3cf6d6dfbb8463", // 158 pool ID
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
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
        // "0xaf3b2b789b70339ac56f23c2c8bfd0edd2b1b496f174aefa46880e011fc86187", // pool ID
      ],
      [
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c", // target token - SolvBTC.TRADING
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xc0aefb6754da0510f31decd714b5b3f349b4bf1875c1ab6ddafedba6f33d3e72", // pool ID
      ],
      [
        "0x89E573571B6786b11643585acbCcF3Cb3ABef81e", // target token - SolvBTC.DEFI
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xde178805efb7fbbf779048a5a09fb176f7c28fb87204718fcc9c6f927eea8140", // pool ID
      ],
      [
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f", // target token - BTC+
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xabea71e4a42c2f072d4e8b35aaf29bb7ac7cf1eeb8def8f9249c414f25081600", // 161 pool ID
      ],
    ],
    avax_test: [
      [
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // target token - SolvBTC
        "0xf04425f8aAdb0A3b59C0124A674A746D59AcD099", // currency - TBTC
        "0x8ed75126966eb7f60a0fef6d22828655193e674d0006988889d00ee9f150a643", // 106 pool ID
      ],
      [
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c", // target token - SolvBTC.TRADING
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0xbea049b6d33f16654613523da17a07d145c1bf234f7925f2562fde10436a6990", // 109 pool ID
      ],
      [
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f", // target token - BTC+
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9", // currency - SolvBTC
        "0x2e3abd3de5544c2336315699d93b96a89c224b6dd009e902330ad71e71fe650f", // 160 pool ID
      ],
    ],
    mainnet: [
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // target token - SolvBTC
        "0xC96dE26018A54D51c097160568752c4E3BD6C364", // currency - FBTC
        "0x2dc130e46b5958208155546bd4049d5b3319798063a8c4180b4b2b82f3ebdc3d", // 136 pool ID
      ],
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // target token - SolvBTC
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // currency - WBTC
        "0x716db7dc196abe78d5349c7166896f674ab978af26ada3e5b3ea74c5a1b48307", // 186 pool ID
      ],
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // target token - SolvBTC
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0xdc0937dd33c4af08a08724da23bc45b33b43fbb23f365e7b50a536ce45f447ef", // 224 pool ID
      ],
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // target token - SolvBTC
        "0x18084fbA666a33d37592fA2633fD49a74DD93a88", // currency - tBTC
        "0x23299b545056e9846725f89513e5d7f65a5034ab36515287ff8a27e860b1be75", // 232 pool ID
      ],
      [
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // target token - xSolvBTC
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // currency - SolvBTC
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
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
      [
        "0xCEa2DAf93617B97504E05AFfc5BCF9b3922D3034", // target token - BTC+
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97", // currency - SolvBTC
        "0x8c30d7ea7c682f3f8ec65beaba1c21755fc5c6976f4c979da06abee7c5890e8f", // 369 fund pool ID
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
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
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
      [
        "0x53E63a31fD1077f949204b94F431bCaB98F72BCE", // target token - SolvBTC.TRADING
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x4d4a6c1ec2386c5149c520a3c278dec0044bdac5798cfbb63ce224227b9899c5", // 117 fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0xd3b1d3c5c203cd23f4fc80443559069b1e313302a10a86d774345dc4ad81b0f6", // 382 fund pool ID
      ],
      [
        "0x52a912a78d9261A2AAEbc4834f84DE9f77a2d03a", // target token - SolvBTC.RWA
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x792c824f8f8defb1ee915e99659fca391501afb15f6a19b95276100883d5a085", // 384 fund pool ID
      ],
      [
        "0x0dE7336C70a8dAd4bdEa1b2BCa8Efb3c955e989D", // target token - SolvBTC.STRK
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0xc00e76915c5091b4ec0d8aeb9626cffa73f20cfe666d5c7108c41e9a34e91532", // 385 fund pool ID
      ],
      [
        "0x8260c40bedDcB8f63c56B6C73476Ef5e20f156A5", // target token - SolvBTC.HYBRID
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x84c98d5afd1404a78bd067985d1c93aea8d5b182ad5be0a7a367fbe747a3de33", // 388 fund pool ID
      ],
      [
        "0x3f88888909544a2C858A790ED77C612076C0bD39", // target token - SolvBTC.Multi-Strategy
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x6317a8c76e0402e8d97a29517888d3048cfa1ac48fb502b7790ea718bf68a4f9", // 399 fund pool ID
      ],
    ],
    mantle: [
      [
        "0xa68d25fC2AF7278db4BcdcAabce31814252642a9", // target token - SolvBTC
        "0xc96de26018a54d51c097160568752c4e3bd6c364", // currency - FBTC
        "0x5fb3c44123fbc670235d925a21f34b75bc33a7d48bee64341dc75aadda58988d", // 180 fund pool ID
      ],
      [
        "0x1d40baFC49c37CdA49F2a5427E2FB95E1e3FCf20", // target token - xSolvBTC
        "0xa68d25fC2AF7278db4BcdcAabce31814252642a9", // currency - SolvBTC
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
      ],
    ],
    avax: [
      [
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", // target token - SolvBTC
        "0x152b9d0FdC40C096757F570A51E494bd4b943E50", // currency - BTC.b
        "0xf5ae38da3319d22b4628e635f6fa60bf966de13c5334b6845eba764d6321e16b", // 183 fund pool ID
      ],
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // target token - xSolvBTC
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", // currency - SolvBTC
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
      ],
      [
        "0x6C7d727a0432D03351678F91FAA1126a5B871DF5", // target token - SolvBTC.AVAX
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", // currency - SolvBTC
        "0x83933f7cabce9efa8ed17c7f601dba81cfa49f0dabaf2885bf1624719bf78443", // 344 fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777", // currency - SolvBTC
        "0x2af9049acd74a38a57bf5299463042bd2b9a8d525bfbbe640f84d099651a77fc", // 377 fund pool ID
      ],
    ],
    arb: [
      [
        "0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0", // target token - SolvBTC
        "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f", // currency - WBTC
        "0x488def4a346b409d5d57985a160cd216d29d4f555e1b716df4e04e2374d2d9f6", // 74 fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0", // currency - SolvBTC
        "0x88b47de44e1954c8d5849c964ac424f6e636ca5b89f0eae4e47902bf5678841f", // 381 fund pool ID
      ],
    ],
    base: [
      [
        "0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f", // target token - SolvBTC
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0x0d85d41382f6f2effeaa41a46855870ec8b1577c6c59cf16d72856a22988e3f5", // 200 fund pool ID
      ],
      [
        "0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f", // target token - SolvBTC
        "0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b", // currency - tBTC
        "0x1706a4881586917b18c2274dfdbcdffe48ee22e18c99090dcee7dd38464526b4", // 226 fund pool ID
      ],
      [
        "0xC26C9099BD3789107888c35bb41178079B282561", // target token - xSolvBTC
        "0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f", // currency - SolvBTC
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f", // currency - SolvBTC
        "0x8062a56325411007013e749ed9f1a2b39e676171122e88d5230012879af9c54b", // 370 fund pool ID
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
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
      ],
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // currency - xSolvBTC
        "0xdecbbc2d7327df6a7123775568b05eb192cc30c3156fe875698689d70dbc7d2c", // 353 fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0xad64f76b02f1758f87254bf52340452a6589bc7975ba424edda8585384bfa736", // 374 fund pool ID
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
        "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff", // special fund pool ID
      ],
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // currency - xSolvBTC
        "0x2bfddb460b2050c9e7567eec1f3ac39c1766a404299038080a4ad7ec294b6425", // 356 fund pool ID
      ],
      [
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F", // target token - SolvBTC.BNB
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x2fad59251e2d7208c181067918f9424088358380f47b582948225d8f887f1b6d", // 365 fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x7f712c24cedabb020f303f07650d19c94a93d71ca928ed614ece8b15aef85150", // 375 fund pool ID
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
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", // currency - SolvBTC
        "0x3d531b19bb21df9f08e2327e0acf63dd9ae416e782acbc3683cfd1851a536d15", // 376 fund pool ID
      ],
    ],
    rootstock: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // target token - SolvBTC
        "0x542fda317318ebf1d3deaf76e0b632741a7e677d", // currency - wrBTC
        "0xf565aa1c019284a525d3157a65249ab8eae5792d52607b5469304b883afe1298", // 334 fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x0487e6f7eb5b48ed910a8720b380ba97e89354ab91db4a24b3bd462bed7b21ee", // 386 fund pool ID
      ],
    ],
    xlayer: [
      [
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", // target token - SolvBTC
        "0xb7C00000bcDEeF966b20B3D884B98E64d2b06b4f", // currency - xBTC
        "", //  fund pool ID
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3", // currency - SolvBTC
        "", // fund pool ID
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
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x3acF2f3C24717113fB72da17565B3acacabA8595", // target token - SolvBTC.TRADING
        ["0xe8C3edB09D1d155292BE0453d57bC3250a0084B6"], // path
      ],
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0xBfE4B499B55084da6a0dA89E0254893B241Dca18", // target token - BTC+
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
      [
        "0x7A9689202fddE4C2091B480c70513184b2F8555C", // currency - WBTC
        "0x96231D57c60C0d64d14F080d771a98FDaDD2Ec8A", // target token - SolvBTC.TRADING
        ["0xE33109766662932a26d978123383ff9E7bdeF346"], // path: WBTC -> SolvBTC -> SolvBTC.TRADING
      ],
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x96231D57c60C0d64d14F080d771a98FDaDD2Ec8A", // target token - SolvBTC.TRADING
        ["0xE33109766662932a26d978123383ff9E7bdeF346"], // path: SBTC -> SolvBTC -> SolvBTC.TRADING
      ],
      [
        "0x7A9689202fddE4C2091B480c70513184b2F8555C", // currency - WBTC
        "0x72B6573FCB8d54522C28689e0aA0B6C77fD245ed", // target token - BTC+
        ["0xE33109766662932a26d978123383ff9E7bdeF346"], // path: WBTC -> SolvBTC -> BTC+
      ],
      [
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0", // currency - SBTC
        "0x72B6573FCB8d54522C28689e0aA0B6C77fD245ed", // target token - BTC+
        ["0xE33109766662932a26d978123383ff9E7bdeF346"], // path: SBTC -> SolvBTC -> BTC+
      ],
    ],
    bsctest: [
      [
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E", // currency - BTCB
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c", // target token - SolvBTC.TRADING
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
      [
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E", // currency - BTCB
        "0x89E573571B6786b11643585acbCcF3Cb3ABef81e", // target token - SolvBTC.DEFI
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
      [
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E", // currency - BTCB
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f", // target token - BTC+
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
    ],
    avax_test: [
      [
        "0xf04425f8aAdb0A3b59C0124A674A746D59AcD099", // currency - TBTC
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c", // target token - SolvBTC.TRADING
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
      [
        "0xf04425f8aAdb0A3b59C0124A674A746D59AcD099", // currency - TBTC
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f", // target token - BTC+
        ["0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9"], // path
      ],
    ],
    mainnet: [
      [
        "0xC96dE26018A54D51c097160568752c4E3BD6C364", // currency - FBTC
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // target token - xSolvBTC
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: FBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // currency - WBTC
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // target token - xSolvBTC
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: WBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // target token - xSolvBTC
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: cbBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0x18084fbA666a33d37592fA2633fD49a74DD93a88", // currency - tBTC
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf", // target token - xSolvBTC
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: tBTC -> SolvBTC -> xSolvBTC
      ],
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
      [
        "0xC96dE26018A54D51c097160568752c4E3BD6C364", // currency - FBTC
        "0xCEa2DAf93617B97504E05AFfc5BCF9b3922D3034", // target token - BTC+
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: FBTC -> SolvBTC -> BTC+
      ],
      [
        "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // currency - WBTC
        "0xCEa2DAf93617B97504E05AFfc5BCF9b3922D3034", // target token - BTC+
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: WBTC -> SolvBTC -> BTC+
      ],
      [
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0xCEa2DAf93617B97504E05AFfc5BCF9b3922D3034", // target token - BTC+
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: cbBTC -> SolvBTC -> BTC+
      ],
      [
        "0x18084fbA666a33d37592fA2633fD49a74DD93a88", // currency - tBTC
        "0xCEa2DAf93617B97504E05AFfc5BCF9b3922D3034", // target token - BTC+
        ["0x7A56E1C57C7475CCf742a1832B028F0456652F97"], // path: tBTC -> SolvBTC -> BTC+
      ],
    ],
    bsc: [
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x1346b618dC92810EC74163e4c27004c921D446a5", // target token - xSolvBTC
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
        "0x53E63a31fD1077f949204b94F431bCaB98F72BCE", // target token - SolvBTC.TRADING
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path: BTCB -> SolvBTC -> SolvBTC.TRADING
      ],
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        [
          "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7",
          "0x1346b618dC92810EC74163e4c27004c921D446a5",
        ], // path: BTCB -> SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7", // currency - SolvBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0x1346b618dC92810EC74163e4c27004c921D446a5"], // path: SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path - SolvBTC
      ],
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x52a912a78d9261A2AAEbc4834f84DE9f77a2d03a", // target token - SolvBTC.RWA
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path - SolvBTC
      ],
      [
        "0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c", // currency - BTCB
        "0x0dE7336C70a8dAd4bdEa1b2BCa8Efb3c955e989D", // target token - SolvBTC.STRK
        ["0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7"], // path - SolvBTC
      ],
    ],
    avax: [
      [
        "0x152b9d0FdC40C096757F570A51E494bd4b943E50", // currency - BTC.b
        "0x6C7d727a0432D03351678F91FAA1126a5B871DF5", // target token - SolvBTC.AVAX
        ["0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777"], // path - SolvBTC
      ],
      [
        "0x152b9d0FdC40C096757F570A51E494bd4b943E50", // currency - BTC.b
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // target token - xSolvBTC
        ["0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777"], // path: BTC.b -> SolvBTC -> xSolvBTC
      ],
      [
        "0x152b9d0FdC40C096757F570A51E494bd4b943E50", // currency - BTC.b
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777"], // path: BTC.b -> SolvBTC -> BTC+
      ],
    ],
    arb: [
      [
        "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f", // currency - WBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0"], // path: WBTC -> SolvBTC -> BTC+
      ],
    ],
    base: [
      [
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0xC26C9099BD3789107888c35bb41178079B282561", // target token - xSolvBTC
        ["0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f"], // path: cbBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b", // currency - tBTC
        "0xC26C9099BD3789107888c35bb41178079B282561", // target token - xSolvBTC
        ["0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f"], // path: tBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf", // currency - cbBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f"], // path: cbBTC -> SolvBTC -> BTC+
      ],
      [
        "0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b", // currency - tBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f"], // path: tBTC -> SolvBTC -> BTC+
      ],
    ],
    bob: [
      [
        "0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3", // currency - WBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        [
          "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77",
          "0xCC0966D8418d412c599A6421b760a847eB169A8c",
        ], // path: BTCB -> SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0xCC0966D8418d412c599A6421b760a847eB169A8c"], // path: SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3", // currency - WBTC
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // target token - xSolvBTC
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77"], // path: WBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0x03C7054BCB39f7b2e5B2c7AcB37583e32D70Cfa3", // currency - WBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77"], // path: WBTC -> SolvBTC -> BTC+
      ],
    ],
    mantle: [
      [
        "0xc96de26018a54d51c097160568752c4e3bd6c364", // currency - FBTC
        "0x1d40baFC49c37CdA49F2a5427E2FB95E1e3FCf20", // target token - xSolvBTC
        ["0xa68d25fC2AF7278db4BcdcAabce31814252642a9"], // path: FBTC -> SolvBTC -> xSolvBTC
      ],
    ],
    bera: [
      [
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c", // currency - WBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        [
          "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77",
          "0xCC0966D8418d412c599A6421b760a847eB169A8c",
        ], // path: BTCB -> SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77", // currency - SolvBTC
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B", // target token - SolvBTC.BERA
        ["0xCC0966D8418d412c599A6421b760a847eB169A8c"], // path: SolvBTC -> xSolvBTC -> SolvBTC.BERA
      ],
      [
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c", // currency - WBTC
        "0xCC0966D8418d412c599A6421b760a847eB169A8c", // target token - xSolvBTC
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77"], // path: WBTC -> SolvBTC -> xSolvBTC
      ],
      [
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c", // currency - WBTC
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F", // target token - SolvBTC.BNB
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77"], // path: WBTC -> SolvBTC -> SolvBTC.BNB
      ],
      [
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c", // currency - WBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77"], // path: WBTC -> SolvBTC -> BTC+
      ],
    ],
    hyperevm: [
      [
        "0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463", // currency - UBTC
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F", // target token - SolvBTC.BNB
        ["0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3"], // path: UBTC -> SolvBTC -> SolvBTC.BNB
      ],
      [
        "0x9FDBdA0A5e284c32744D2f17Ee5c74B284993463", // currency - UBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3"], // path: UBTC -> SolvBTC -> BTC+
      ],
    ],
    rootstock: [
      [
        "0x542fda317318ebf1d3deaf76e0b632741a7e677d", // currency - wrBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0x541FD749419CA806a8bc7da8ac23D346f2dF8B77"], // path: UBTC -> SolvBTC -> BTC+
      ],
    ],
    xlayer: [
      [
        "0xb7C00000bcDEeF966b20B3D884B98E64d2b06b4f", // currency - xBTC
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad", // target token - BTC+
        ["0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3"], // path: xBTC -> SolvBTC -> BTC+
      ],
    ],
  };

  const multiAssetPools = {
    dev_sepolia: [
      [
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6",
        "0xBdF15396e8A49773386fBA396D74dbbB8ED993f2",
      ], // SolvBTC
      [
        "0x49aFCf847193c48091969bdB20852ef4c5A534D7",
        "0xc57C23278e0C02998bbA7D5a842A49F34744d4ce",
      ], // SolvBTC.BERA
      [
        "0x7157D9B6bEF77BDC9e8162659239252DD9FB875C",
        "0xc57C23278e0C02998bbA7D5a842A49F34744d4ce",
      ], // SolvBTC.BNB
      [
        "0x3acF2f3C24717113fB72da17565B3acacabA8595",
        "0xc57C23278e0C02998bbA7D5a842A49F34744d4ce",
      ], // SolvBTC.TRADING
      [
        "0xBfE4B499B55084da6a0dA89E0254893B241Dca18",
        "0xc57C23278e0C02998bbA7D5a842A49F34744d4ce",
      ], // BTC+
    ],
    sepolia: [
      [
        "0xE33109766662932a26d978123383ff9E7bdeF346",
        "0xeC8A36eF9b006abf8c477bD82c649067DB2A3769",
      ], // SolvBTC
      [
        "0x96231D57c60C0d64d14F080d771a98FDaDD2Ec8A",
        "0x58D91F2A23ddB50Cc699424e9E74097A51509b7c",
      ], // SolvBTC.TRADING
      [
        "0xf44c01111C54C550d044025099220D79B9559EB9",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0",
        "0x58D91F2A23ddB50Cc699424e9E74097A51509b7c",
      ], // SolvBTC.BERA
      [
        "0x72B6573FCB8d54522C28689e0aA0B6C77fD245ed",
        "0x58D91F2A23ddB50Cc699424e9E74097A51509b7c",
      ], // BTC+
    ],
    bsctest: [
      [
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9",
        "0xED714AC014a11e758af1Fbc53d3B8a6F3056a1F8",
      ], // SolvBTC
      [
        "0xB4618618b6Fcb61b72feD991AdcC344f43EE57Ad",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x89E573571B6786b11643585acbCcF3Cb3ABef81e",
        "0x56006176aEe38928ea658A80De972E9232521026",
      ], // SolvBTC.DeFi
      [
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c",
        "0x56006176aEe38928ea658A80De972E9232521026",
      ], // SolvBTC.TRADING
      [
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f",
        "0x56006176aEe38928ea658A80De972E9232521026",
      ], // BTC+
    ],
    avax_test: [
      [
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9",
        "0x51D8883C096E4697e20eE110DcF4d2d30678f6BB",
      ], // SolvBTC
      [
        "0xaDAe5fc8d830f86f53E20c8a39F7E12Ff6d4E87c",
        "0xad060cf4f583f3430039A4977405cf2D9518A23B",
      ], // SolvBTC.TRADING
      [
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f",
        "0xad060cf4f583f3430039A4977405cf2D9518A23B",
      ], // BTC+
    ],
    mainnet: [
      [
        "0x7A56E1C57C7475CCf742a1832B028F0456652F97",
        "0x1d5262919C4AAb745A8C9dD56B80DB9FeaEf86BA",
      ], // SolvBTC
      [
        "0xd9D920AA40f578ab794426F5C90F6C731D159DEf",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0xE7C253EAD50976Caf7b0C2cbca569146A7741B50",
        "0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D",
      ], // SolvBTC.BERA
      [
        "0x32Bc653dbD08C70f4dDEF2Bab15915193A617D75",
        "0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D",
      ], // SolvBTC.DLP
      [
        "0xCEa2DAf93617B97504E05AFfc5BCF9b3922D3034",
        "0x763b8a88Ac40eDb6Cc5c13FAac1fCFf4b393218D",
      ], // BTC+
    ],
    bsc: [
      [
        "0x4aae823a6a0b376De6A78e74eCC5b079d38cBCf7",
        "0x1FF72318deeD339e724e3c8deBCD528dC013D845",
      ], // SolvBTC
      [
        "0x1346b618dC92810EC74163e4c27004c921D446a5",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x647A50540F5a1058B206f5a3eB17f56f29127F53",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.DeFi
      [
        "0x6c948A4C31D013515d871930Fe3807276102F25d",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.BNB
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.BERA
      [
        "0x53E63a31fD1077f949204b94F431bCaB98F72BCE",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.TRADING
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // BTC+
      [
        "0x52a912a78d9261A2AAEbc4834f84DE9f77a2d03a",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.RWA
      [
        "0x0dE7336C70a8dAd4bdEa1b2BCa8Efb3c955e989D",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.STRK
      [
        "0x8260c40bedDcB8f63c56B6C73476Ef5e20f156A5",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.HYBRID
      [
        "0x3f88888909544a2C858A790ED77C612076C0bD39",
        "0x2bE4500C50D99A81C8b4cF8DA10C5EDbaE6A234A",
      ], // SolvBTC.Multi-Strategy
    ],
    mantle: [
      [
        "0xa68d25fC2AF7278db4BcdcAabce31814252642a9",
        "0x9954Ec753e60515Cde96765efF4D35b18542C09f",
      ], // SolvBTC
      [
        "0x1d40baFC49c37CdA49F2a5427E2FB95E1e3FCf20",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
    ],
    avax: [
      [
        "0xbc78D84Ba0c46dFe32cf2895a19939c86b81a777",
        "0x0BA5f53a4Bf22C9e5947aeb6eA4521D030f35705",
      ], // SolvBTC
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x6C7d727a0432D03351678F91FAA1126a5B871DF5",
        "0x814F3ae67dF0da9fe2399a29516FD14b9085263a",
      ], // SolvBTC.AVAX
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0x814F3ae67dF0da9fe2399a29516FD14b9085263a",
      ], // BTC+
    ],
    arb: [
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0x0679E96f5EEDa5313099f812b558714717AEC176",
      ], // BTC+
    ],
    base: [
      [
        "0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f",
        "0x540a9DBBA1AE6250253ba8793714492ee357ac1D",
      ], // SolvBTC
      [
        "0xC26C9099BD3789107888c35bb41178079B282561",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0xD7bf464839a28969846F2E0d1709d61c281d7888",
      ], // BTC+
    ],
    bob: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77",
        "0xc2f69541e3dC306777D260dC66bfD54fcb897100",
      ], // SolvBTC
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B",
        "0xd157B70F917fEf3A59502b9128feCA911dEbC864",
      ], // SolvBTC.BERA
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0xd157B70F917fEf3A59502b9128feCA911dEbC864",
      ], // BTC+
    ],
    bera: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77",
        "0xf4F39602D0a6C8f60C23208819140F2C3FA1662C",
      ], // SolvBTC
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c",
        (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address,
      ], // xSolvBTC
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B",
        "0xeC34989BECD59158f3B1A5cdfFDb667fa2e4d957",
      ], // SolvBTC.BERA
      [
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F",
        "0xeC34989BECD59158f3B1A5cdfFDb667fa2e4d957",
      ], // SolvBTC.BNB
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0xeC34989BECD59158f3B1A5cdfFDb667fa2e4d957",
      ], // BTC+
    ],
    hyperevm: [
      [
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3",
        "0x45fb21ac62503c0Bb6FfF3513a3D0fFAAA11aCDb",
      ], // SolvBTC
      [
        "0xc99F5c922DAE05B6e2ff83463ce705eF7C91F077",
        "0x2DC5392c35e6682ed27EDE187AC159BA020a5eda",
      ], // xSolvBTC
      [
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F",
        "0x2DC5392c35e6682ed27EDE187AC159BA020a5eda",
      ], // SolvBTC.BNB
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0x2DC5392c35e6682ed27EDE187AC159BA020a5eda",
      ], // BTC+
    ],
    rootstock: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77",
        "0xf4F39602D0a6C8f60C23208819140F2C3FA1662C",
      ], // SolvBTC
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "0xeC34989BECD59158f3B1A5cdfFDb667fa2e4d957",
      ], // BTC+
    ],
    xlayer: [
      [
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3",
        "",
      ], // SolvBTC
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",
        "",
      ], // BTC+
    ],
  };

  const contractName = "SolvBTCRouterV2";
  const firstImplName = contractName + "Impl";
  const proxyName = contractName + "Proxy";

  const versions = {
    dev_sepolia: ["v2.1", "v2.2", "v2.3", "v2.4"],
    sepolia: ["v2.1", "v2.2", "v2.3", "v2.4"],
    bsctest: ["v2.1", "v2.2", "v2.3", "v2.4"],
    mainnet: ["v2.1", "v2.3", "v2.4"],
    bsc: ["v2.1", "v2.3", "v2.4"],
    mantle: ["v2.2", "v2.3"],
    bob: ["v2.2", "v2.3"],
    avax: ["v2.3"],
    bera: ["v2.3", "v2.4"],
    arb: ["v2.4"],
    ink: ["v2.4"],
    base: ["v2.4"],
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
          args: [owner, market[network.name]],
        },
        upgrades: upgrades,
      }
    );

  const SolvBTCRouterV2Factory = await ethers.getContractFactory(
    "SolvBTCRouterV2",
    deployer
  );
  const solvBTCRouterV2 = SolvBTCRouterV2Factory.attach(proxy.address);

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

  for (let multiAssetPool of multiAssetPools[network.name]) {
    let currentPool = await solvBTCRouterV2.multiAssetPools(multiAssetPool[0]);
    if (currentPool != multiAssetPool[1]) {
      let setPoolTx = await solvBTCRouterV2.setMultiAssetPool(
        multiAssetPool[0],
        multiAssetPool[1]
      );
      console.log(
        `Set MultiAssetPool for token ${multiAssetPool[0]} at tx: ${setPoolTx.hash}`
      );
      await setPoolTx.wait(1);
    }
  }

};

module.exports.tags = ["SolvBTCRouterV2"];
