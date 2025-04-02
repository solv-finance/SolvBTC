import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "hardhat-deploy-ethers";

import "@matterlabs/hardhat-zksync-deploy";
import "@matterlabs/hardhat-zksync-solc";
import "@matterlabs/hardhat-zksync-ethers";
import "@matterlabs/hardhat-zksync-node";
import "@matterlabs/hardhat-zksync-verify";
import "@matterlabs/hardhat-zksync-upgradable";

import { execSync } from "child_process";

import dotenv from "dotenv";
dotenv.config();

// Get master password using synchronous method
function getMasterKey() {
  try {
    process.stdout.write("Enter your master password: ");
    // Use spawnSync instead of execSync
    const { spawnSync } = require("child_process");
    const result = spawnSync("bash", ["-c", "read -s line && echo $line"], {
      stdio: ["inherit", "pipe", "inherit"],
      encoding: "utf8",
    });
    const masterKey = result.stdout.trim();
    return masterKey;
  } catch (error) {
    console.error("Error getting master password:", error);
    process.exit(1);
  }
}

function getPrivateKey() {
  try {
    const masterKey = getMasterKey();
    return execSync(
      `export MASTER_KEY=${masterKey} && /usr/local/bin/solv-key dec`,
      { encoding: "utf8" } // Add encoding option
    )
      .split("=")[0]
      .trim();
  } catch (error) {
    console.error("Error getting private key:", error);
    process.exit(1);
  }
}

const PRIVATE_KEY = process.env.PRIVATE_KEY || getPrivateKey();

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
  zksolc: {
    version: "1.5.8",
    settings: {},
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      zksync: true,
    },
    sepolia: {
      url: "https://ethereum-sepolia-rpc.publicnode.com",
      accounts: [process.env.PRIVATE_KEY as any],
      zksync: false,
    },
    mainnet: {
      url:
        process.env.ETH_URL ||
        `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
      zksync: false,
    },
    zksyncSepolia: {
      url: "https://sepolia.era.zksync.dev",
      ethNetwork: "sepolia",
      accounts: [process.env.PRIVATE_KEY as any],
      zksync: true,
      verifyURL:
        "https://explorer.sepolia.era.zksync.dev/contract_verification",
    },
    zkSyncMainnet: {
      url: "https://mainnet.era.zksync.io",
      ethNetwork: "mainnet",
      accounts: [process.env.PRIVATE_KEY as any],
      zksync: true,
      verifyURL:
        "https://zksync2-mainnet-explorer.zksync.io/contract_verification",
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  etherscan: {
    apiKey: {
      sepolia: process.env.ETHERSCAN_API_KEY as any,
      mainnet: process.env.ETHERSCAN_API_KEY as any,
      zksyncsepolia: process.env.ETHERSCAN_API_KEY as any,
      zkSyncMainnet: process.env.ETHERSCAN_API_KEY as any,
    },
  },
};

export default config;
