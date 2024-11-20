import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-deploy";
import "hardhat-tracer";

import * as dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
    ],
  },

  namedAccounts: {
    deployer: 0,
  },

  networks: {
    hardhat: {},
    localhost: {},
    dev_goerli: {
      url:
        process.env.GOERLI_URL ||
        `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    dev_mumbai: {
      url: process.env.MUMBAI_URL || `https://rpc-mumbai.maticvigil.com/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    dev_sepolia: {
      url:
        process.env.SEPOLIA_URL ||
        `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url:
        process.env.GOERLI_URL ||
        `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    sepolia: {
      url:
        process.env.SEPOLIA_URL ||
        `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsctest: {
      url:
        process.env.BSC_TESTNET_URL ||
        `https://rpc.ankr.com/bsc_testnet_chapel`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    arb_goerli: {
      url:
        process.env.ARB_GOERLI_URL ||
        `https://arb-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mantle_testnet: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.testnet.mantle.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    merlin_test: {
      url: process.env.MERLIN_TEST_URL || `https://testnet-rpc.merlinchain.io`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mumbai: {
      url: process.env.MUMBAI_URL || `https://rpc-mumbai.maticvigil.com/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    ailayer_test: {
      url: process.env.AILAYER_TEST_URL || `https://testnet-rpc.ailayer.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    avax_test: {
      url:
        process.env.AVAX_TEST_URL ||
        `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bob_test: {
      url: process.env.BOB_TEST_URL || `https://testnet.rpc.gobob.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    core_test: {
      url: process.env.CORE_TEST_URL || `https://rpc.test.btcs.network`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    base_test: {
      url: process.env.BASE_TEST_URL || `https://sepolia.base.org`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    taiko_test: {
      url: process.env.TAIKO_TEST_URL || `https://rpc.hekla.taiko.xyz`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    hashkey_test: {
      url:
        process.env.HASHKEY_TEST_URL ||
        `https://hsk-scroll-testnet-rpc.alt.technology`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mode_test: {
      url: process.env.MODE_TEST_URL || `https://sepolia.mode.network`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    form_test: {
      url: process.env.FORM_TEST_URL || `https://testnet-rpc.form.network/http`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bera_test: {
      url: process.env.BERA_TEST_URL || `https://bartio.rpc.berachain.com/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    linea_test: {
      url: process.env.LINEA_TEST_URL || `https://linea-sepolia.blockpi.network/v1/rpc/public`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url:
        process.env.GOERLI_URL ||
        `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    polygon: {
      url: "https://polygon-rpc.com/",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsc: {
      url: process.env.BSC_URL || `https://bsc-dataseed.binance.org/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    arb: {
      url:
        process.env.ARB_URL ||
        `https://arb.getblock.io/${process.env.GETBLOCK_KEY}/mainnet/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mantle: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.mantle.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    merlin: {
      url: process.env.MERLIN_URL || ` https://rpc.merlinchain.io`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    ailayer: {
      url: process.env.AILAYER_URL || `https://mainnet-rpc.ailayer.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    avax: {
      url: process.env.AVAX_URL || `https://api.avax.network/ext/bc/C/rpc`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bob: {
      url: process.env.BOB_URL || `https://rpc.gobob.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    base: {
      url: process.env.BASE_URL || `https://mainnet.base.org/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    core: {
      url: process.env.CORE_URL || `https://rpc.ankr.com/core`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    taiko: {
      url: process.env.CORE_URL || `https://rpc.mainnet.taiko.xyz`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mode: {
      url: process.env.CORE_URL || `https://mainnet.mode.network`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },

  etherscan: {
    apiKey: {
      bsc: process.env.BSCSCAN_API_KEY || "",
      arb: process.env.ARBISCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      merlin: process.env.MERLINSCAN_API_KEY || "",
      mantle: "mantle",
      avax: "avax",
    },
    customChains: [
      {
        network: "arb",
        chainId: 42161,
        urls: {
          apiURL: "https://api.arbiscan.io/api",
          browserURL: "https://explorer.arbitrum.io",
        },
      },
      {
        network: "merlin",
        chainId: 4200,
        urls: {
          apiURL: "https://scan.merlinchain.io/api/",
          browserURL: "https://scan.merlinchain.io",
        },
      },
      {
        network: "mantle",
        chainId: 5000,
        urls: {
          apiURL: "https://explorer.mantle.xyz/api",
          browserURL: "https://explorer.mantle.xyz/",
        },
      },
      {
        network: "avax",
        chainId: 43114,
        urls: {
          apiURL:
            "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan/api",
          browserURL: "https://snowtrace.io/",
        },
      },
    ],
  },
};

export default config;
