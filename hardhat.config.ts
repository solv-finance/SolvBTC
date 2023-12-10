import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "hardhat-tracer";

import * as dotenv from 'dotenv';
dotenv.config()

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
    ]
  },

  namedAccounts: {
    deployer: 0
  },

  networks: {
    hardhat: {},
    localhost: {},
    dev_goerli: {
      url: process.env.GOERLI_URL || `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    dev_mumbai: {
      url: process.env.MUMBAI_URL || `https://rpc-mumbai.maticvigil.com/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    goerli: {
      url: process.env.GOERLI_URL || `https://goerli.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    sepolia: {
      url: process.env.SEPOLIA_URL || `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    bsctest: {
      url: process.env.BSC_TESTNET_URL || `https://rpc.ankr.com/bsc_testnet_chapel`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    arb_goerli: {
      url: process.env.ARB_GOERLI_URL || `https://arb-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mantle_testnet: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.testnet.mantle.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mumbai: {
      url: process.env.MUMBAI_URL || `https://rpc-mumbai.maticvigil.com/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mainnet: {
      url: process.env.GOERLI_URL || `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
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
      url: process.env.ARB_URL || `https://arb.getblock.io/${process.env.GETBLOCK_KEY}/mainnet/`,
      accounts: 
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    mantle: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.mantle.xyz/`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },

  etherscan: {
    apiKey: {
      mantle: 'mantle',
      goerli: process.env.ETHERSCAN_API_KEY || '',
    },
    customChains: [
      {
        network: "mantle",
        chainId: 5000,
        urls: {
          apiURL: "https://explorer.mantle.xyz/api",
          browserURL: "https://explorer.mantle.xyz/"
        }
      }
    ]
  },
};

export default config;