const colors = require("colors");
const { txWait } = require("./utils/deployUtils");
const assert = require("assert");
const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments, network }) => {
  const { deployer } = await getNamedAccounts();

  const feeConfigs = {
    dev_sepolia: [
      [
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6",  // targetToken: SolvBTC
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0",  // currency: SBTC
        0.01e8,                                        // feeRate
        "0x4b2e4cAc67786778c79beCcC8c800E325Ab3bDDa",  // feeReceiver
      ],
      [
        "0xe8C3edB09D1d155292BE0453d57bC3250a0084B6",  // targetToken: SolvBTC
        "0x7A9689202fddE4C2091B480c70513184b2F8555C",  // currency: WBTC
        0.015e8,                                       // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
      [
        "0xBfE4B499B55084da6a0dA89E0254893B241Dca18",  // targetToken: BTC+
        "0x1418511884942f7Da13f3C2B19088a4E3B36CCD0",  // currency: SBTC
        0.005e8,                                       // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
    ],
    sepolia: [
      [
        "0xE33109766662932a26d978123383ff9E7bdeF346",  // targetToken: SolvBTC
        "0x7A9689202fddE4C2091B480c70513184b2F8555C",  // currency: WBTC
        0.01e8,                                        // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
      [
        "0x8146034b06C4ab83d7a59614b64e62705d4dC0C0",  // targetToken: SolvBTC.BREA
        "0x7A9689202fddE4C2091B480c70513184b2F8555C",  // currency: WBTC
        0.01e8,                                        // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
      [
        "0x72B6573FCB8d54522C28689e0aA0B6C77fD245ed",  // targetToken: BTC+
        "0x7A9689202fddE4C2091B480c70513184b2F8555C",  // currency: WBTC
        0.01e8,                                        // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
    ],
    bsctest: [
      [
        "0x1cF0e51005971c5B78b4A8feE419832CFCCD8cf9",  // targetToken: SolvBTC
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E",  // currency: BTCB
        0.002e8,                                       // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
      [
        "0x89E573571B6786b11643585acbCcF3Cb3ABef81e",  // targetToken: SolvBTC.DeFi
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E",  // currency: BTCB
        0.002e8,                                       // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
      [
        "0x21baBFc92181Eb8B59dBEe7610642C9802001A1f",  // targetToken: BTC+
        "0xbFEfd7c0BB235E67E314ae65bd9C4685dBE9A45E",  // currency: BTCB
        0.002e8,                                       // feeRate
        "0x35256c3e3be3a9f2A95dD20D39fC61dfa08bBE95",  // feeReceiver
      ],
    ],
    bera: [
      [
        "0x541FD749419CA806a8bc7da8ac23D346f2dF8B77",  // targetToken: SolvBTC
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",  // currency: WBTC
        0.0025e8,                                      // feeRate = 0.25%
        "0x52be8fe8fed6c8d52a9fd94a10dad12f4ffa9526",  // feeReceiver
      ],
      [
        "0xCC0966D8418d412c599A6421b760a847eB169A8c",  // targetToken: xSolvBTC
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",  // currency: WBTC
        0.0025e8,                                      // feeRate = 0.25%
        "0x52be8fe8fed6c8d52a9fd94a10dad12f4ffa9526",  // feeReceiver
      ],
      [
        "0x0F6f337B09cb5131cF0ce9df3Beb295b8e728F3B",  // targetToken: SolvBTC.BERA
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",  // currency: WBTC
        0.0025e8,                                      // feeRate = 0.25%
        "0x52be8fe8fed6c8d52a9fd94a10dad12f4ffa9526",  // feeReceiver
      ],
      [
        "0x1B25cA174c158440621Ff96E4B1262cb5cc8942F",  // targetToken: SolvBTC.BNB
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",  // currency: WBTC
        0.0025e8,                                      // feeRate = 0.25%
        "0x52be8fe8fed6c8d52a9fd94a10dad12f4ffa9526",  // feeReceiver
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",  // targetToken: BTC+
        "0x0555E30da8f98308EdB960aa94C0Db47230d2B9c",  // currency: WBTC
        0.0025e8,                                      // feeRate = 0.25%
        "0x52be8fe8fed6c8d52a9fd94a10dad12f4ffa9526",  // feeReceiver
      ],
    ],
    arb: [
      [
        "0x3647c54c4c2C65bC7a2D63c0Da2809B399DBBDC0",  // targetToken: SolvBTC
        "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",  // currency: WBTC
        0.0030e8,                                      // feeRate = 0.3%
        "0x032470aBBb896b1255299d5165c1a5e9ef26bcD2",  // feeReceiver
      ],
      [
        "0x346c574C56e1A4aAa8dc88Cda8F7EB12b39947aB",  // targetToken: xSolvBTC
        "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",  // currency: WBTC
        0.0030e8,                                      // feeRate = 0.3%
        "0x032470aBBb896b1255299d5165c1a5e9ef26bcD2",  // feeReceiver
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",  // targetToken: BTC+
        "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",  // currency: WBTC
        0.0030e8,                                      // feeRate = 0.3%
        "0x032470aBBb896b1255299d5165c1a5e9ef26bcD2",  // feeReceiver
      ],
      [
        "0xaFAfd68AFe3fe65d376eEC9Eab1802616cFacCb8",  // targetToken: SolvBTC.TRADING
        "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",  // currency: WBTC
        0.0030e8,                                      // feeRate = 0.3%
        "0x032470aBBb896b1255299d5165c1a5e9ef26bcD2",  // feeReceiver
      ],
    ],
    base: [
      [
        "0x3B86Ad95859b6AB773f55f8d94B4b9d443EE931f",  // targetToken: SolvBTC
        "0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b",  // currency: tBTC
        0.0030e8,                                      // feeRate = 0.3%
        "0xF2416C264Aa4068fF4D1949383366458F295F205",  // feeReceiver
      ],
      [
        "0x4Ca70811E831db42072CBa1f0d03496EF126fAad",  // targetToken: BTC+
        "0x236aa50979D5f3De3Bd1Eeb40E81137F22ab794b",  // currency: tBTC
        0.0030e8,                                      // feeRate = 0.3%
        "0xF2416C264Aa4068fF4D1949383366458F295F205",  // feeReceiver
      ],
    ],
    ink: [
      [
        "0xaE4EFbc7736f963982aACb17EFA37fCBAb924cB3",  // targetToken: SolvBTC
        "0x73E0C0d45E048D25Fc26Fa3159b0aA04BfA4Db98",  // currency: KBTC
        0.0010e8,                                      // feeRate = 0.1%
        "0x33b7A7a164B77433A61d4B49bD780a2718812e6e",  // feeReceiver
      ],
    ],
  }

  const FeeManagerFactory = await ethers.getContractFactory("FeeManager", deployer);
  const feeManagerAddress = (await deployments.get("FeeManagerProxy")).address;
  const feeManager = FeeManagerFactory.attach(feeManagerAddress);

  const tx = await feeManager.setDepositFees(feeConfigs[network.name]);
  console.log(`* Set DepositFees at tx ${tx.hash}`);
  await txWait(tx);

};

module.exports.tags = ["FeeManager_Config"];
