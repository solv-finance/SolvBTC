const SolvBTCYieldTokenFactoryAddresses = {
  dev_sepolia: '0xA3aFA754db2EFc80Be3F925c3E47c18752aC72b8',
  sepolia: '',
  mainnet: '',
  arb: '',
  bsc: '',
  merlin: '',
  mantle: '',
}

const SolvBTCYieldTokenBeaconAddresses = {
  dev_sepolia: '0x0C62BEc3Ef44cD5d6b795B37F986Bee6B7Ca9550',
  sepolia: '0x5409D9f1516fFc65DDe006Bf28c3c7Ca642aa71b',
  mainnet: '0xb49De2a621c8540874Ae4B2Ae9a2E59C948645f1',
  arb: '0x7B375C1a95335Ec443f9b610b427e5AfC91E566D',
  bsc: '0xB259aD28968563E75fd442d91426aDE9194b0f71',
  merlin: '0x5339129852204C8466EeBDA420aCbB466c27B9A4',
  mantle: '0x905d782024727dDB1516D66c4762E5CE8F1dc91A',
}

const SolvBTCYieldTokenMultiAssetPoolAddresses = {
  dev_sepolia: '0xc57C23278e0C02998bbA7D5a842A49F34744d4ce',
  sepolia: '',
  mainnet: '',
  arb: '',
  bsc: '',
  merlin: '',
  mantle: '',
}

const SolvBTCYieldTokenInfos = {
  dev_sepolia: {
    'SolvBTC Yield Pool': {
      // https://fm-dev-0ak6s1klbcud.solv.finance/open-fund/management/163/overview
      erc20: '0x3acF2f3C24717113fB72da17565B3acacabA8595',
      sft: '0x1bdA9d2d280054C5CF657B538751dD3bB88671e3',
      slot: '55816906216140072643656852625631805111843385002459235182041733401755343339377',
      poolId: '0x4fade1ad2f41383400b5c0bc6d9c863644bcbbb16a407fb9a0d043f7578b00c5',
      navOracle: '0x6255a8d0485659E7f45D97c3D61e532B3fb01877',
      holdingValueSftId: 133
    },
    'SolvBTC Yield Pool (BBN)': {
      // https://fm-dev-0ak6s1klbcud.solv.finance/open-fund/management/166/overview
      erc20: '0x32Ea1777bC01977a91D15a1C540cbF29bE17D89D',
      sft: '0x1bdA9d2d280054C5CF657B538751dD3bB88671e3',
      slot: '109960959664229641296182064182695512546041565238657772188637862410825890720389',
      poolId: '0xf467da622867671dcea1df40bc43ff07edbbdc370ffd011164abb48a71f02a9a',
      navOracle: '0x6255a8d0485659E7f45D97c3D61e532B3fb01877',
      holdingValueSftId: 171
    },
  },

  sepolia: {
    'SolvBTC Yield Pool': {
      // https://fm-testnet.solv.finance/open-fund/management/73/overview
      erc20: '0x96231D57c60C0d64d14F080d771a98FDaDD2Ec8A',
      sft: '0xB85A099103De07AC3d2C498453a6599D273be701',
      slot: '40157405216900912931362747879010359972656634598029865920249696500324936062978',
      poolId: '0xf82ad2ca2bab8adcf837b1f57b7aa204e479ba03b43aacf585c5ce770158ab39',
      navOracle: '0x2271d9FB0A45b63c781D038d0F44596e865dbc2b',
      holdingValueSftId: 117
    },
    'SolvBTC Yield Pool (BBN)': {
      // https://fm-testnet.solv.finance/open-fund/management/78/overview
      erc20: '0xf44c01111C54C550d044025099220D79B9559EB9',
      sft: '0xB85A099103De07AC3d2C498453a6599D273be701',
      slot: '21525797116469342010147555198495458332450504371225068883909641098487130211639',
      poolId: '0x64a66ad214a02b4136f8ab710e690b31fdbf359c82ecc7814034a5b60287968b',
      navOracle: '0x2271d9FB0A45b63c781D038d0F44596e865dbc2b',
      holdingValueSftId: 152
    },
  },

  mainnet: {
    'SolvBTC Babylon': {
      // https://fund-management.solv.finance/open-fund/management/140/overview
      erc20: '0xd9D920AA40f578ab794426F5C90F6C731D159DEf',
      sft: '0x982D50f8557D57B748733a3fC3d55AeF40C46756',
      slot: '83660682397659272392863020907646506973985956658124321060921311208510599625298',
      poolId: '0xefcca1eb946cdc7b56509489a56b45b75aff74b8bb84dad5b893012157e0df93',
      navOracle: '0x8c29858319614380024093DBEE553F9337665756',
      holdingValueSftId: 2
    }
  },
  
  arb: {
    'SolvBTC Ethena': {
      // https://fund-management.solv.finance/open-fund/management/118/overview
      erc20: '0xaFAfd68AFe3fe65d376eEC9Eab1802616cFacCb8',
      sft: '0x22799DAA45209338B7f938edf251bdfD1E6dCB32',
      slot: '73370673862338774703804051393194258049657950181644297527289682663167654669645',
      poolId: '0x0e11a7249a1ca69c4ed42b0bfcc0e3d8f45de5e510c0d866132fdf078f3849df',
      navOracle: '0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD',
      holdingValueSftId: 4786
    },
    'SolvBTC Babylon': {
      // https://fund-management.solv.finance/open-fund/management/137/overview
      erc20: '0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB', 
      sft: '0x22799DAA45209338B7f938edf251bdfD1E6dCB32',
      slot: '25315353894199778801354907614668596034124918468786689102544470186607665630642',
      poolId: '0xa1a41164e490bee159f8629380d0f52d82d852ba58c35528a0cc8779049416e8',
      navOracle: '0x6ec1fEC6c6AF53624733F671B490B8250Ff251eD',
      holdingValueSftId: 5355
    }
  },

  bsc: {
    'SolvBTC Ethena': {
      // https://fund-management.solv.finance/open-fund/management/117/overview
      erc20: '0x53E63a31fD1077f949204b94F431bCaB98F72BCE',
      sft: '0xB816018E5d421E8b809A4dc01aF179D86056eBDF',
      slot: '89208590061209537649550317104742331433006176747085251606825693434226550591473',
      poolId: '0x4d4a6c1ec2386c5149c520a3c278dec0044bdac5798cfbb63ce224227b9899c5',
      navOracle: '0x9C491539AeC346AAFeb0bee9a1e9D9c02AB50889',
      holdingValueSftId: 168
    },
    'SolvBTC Babylon': {
      // https://fund-management.solv.finance/open-fund/management/135/overview
      erc20: '0x1346b618dC92810EC74163e4c27004c921D446a5',
      sft: '0xB816018E5d421E8b809A4dc01aF179D86056eBDF',
      slot: '1336354853777768727075850191656536701909968430898108410559797247549735288643',
      poolId: '0x6fe7f2753798616f555389f971dae58b32e181fab8b1d60d35e5ddafbb6bb5b7',
      navOracle: '0x9C491539AeC346AAFeb0bee9a1e9D9c02AB50889',
      holdingValueSftId: 907
    },
  },

  merlin: {
    'SolvBTC Ethena': {
      // https://fund-management.solv.finance/open-fund/management/121/overview
      erc20: '0x88c618B2396C1A11A6Aabd1bf89228a08462f2d2',
      sft: '0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe',
      slot: '38110458806523432052630209861008760559065076965924218691659245408576790171249',
      poolId: '0x261e2b89e92a5baab8df45f04b58c280bba7f3d4d0cf49b6a9f72f026327a058',
      navOracle: '0x540a9DBBA1AE6250253ba8793714492ee357ac1D',
      holdingValueSftId: 9
    },
    'SolvBTC Babylon': {
      // https://fund-management.solv.finance/open-fund/management/138/overview
      erc20: '0x1760900aCA15B90Fa2ECa70CE4b4EC441c2CF6c5',
      sft: '0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe',
      slot: '23002376000286537971644610945217253049745413385836602646876543302447601012196',
      poolId: '0x903f661146b7de3d3b1b1e68f22ba295baa8f558a79e7ba1ee91d590b06890ec',
      navOracle: '0x540a9DBBA1AE6250253ba8793714492ee357ac1D',
      holdingValueSftId: 283
    },
  },
  
  mantle: {
    'SolvBTC Babylon': {
      // https://fund-management.solv.finance/open-fund/management/181/overview
      erc20: '0x1d40baFC49c37CdA49F2a5427E2FB95E1e3FCf20',
      sft: '0x788dC3af7B62708b752d483a6E30d1Cf23c3EaAe',
      slot: '12331450637656346719378267501864914478562479812085051740470054359414880794205',
      poolId: '0xbaa315531846ef9d6bddfc9e551c2b90e478a0efcabfef701e62a7268873d5ad',
      navOracle: '0x540a9DBBA1AE6250253ba8793714492ee357ac1D',
      holdingValueSftId: 1019
    },
  }
}

module.exports = {
  SolvBTCYieldTokenFactoryAddresses,
  SolvBTCYieldTokenBeaconAddresses,
  SolvBTCYieldTokenMultiAssetPoolAddresses,
  SolvBTCYieldTokenInfos
}