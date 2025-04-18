import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-deploy";
import "hardhat-tracer";

import { execSync } from "child_process";

import * as dotenv from "dotenv";
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
const taskName = process.argv[2];

function getPrivateKey() {
  if (taskName !== "deploy") {
    return process.env.PRIVATE_KEY || undefined;
  }
  if (process.env.PRIVATE_KEY !== undefined) {
    return process.env.PRIVATE_KEY;
  }
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

const PRIVATE_KEY = getPrivateKey();

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
    dev_sepolia: {
      url:
        process.env.SEPOLIA_URL ||
        `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    sepolia: {
      url:
        process.env.SEPOLIA_URL ||
        `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bsctest: {
      url:
        process.env.BSC_TESTNET_URL || `https://bsc-testnet-rpc.publicnode.com`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    mantle_testnet: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.testnet.mantle.xyz/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    merlin_test: {
      url: process.env.MERLIN_TEST_URL || `https://testnet-rpc.merlinchain.io`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    amoy: {
      url: process.env.AMOY_URL || `https://rpc-amoy.polygon.technology`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    ailayer_test: {
      url: process.env.AILAYER_TEST_URL || `https://testnet-rpc.ailayer.xyz/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    avax_test: {
      url:
        process.env.AVAX_TEST_URL ||
        `https://api.avax-test.network/ext/bc/C/rpc`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bob_test: {
      url: process.env.BOB_TEST_URL || `https://testnet.rpc.gobob.xyz/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    core_test: {
      url: process.env.CORE_TEST_URL || `https://rpc.test.btcs.network`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    base_test: {
      url: process.env.BASE_TEST_URL || `https://sepolia.base.org`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    taiko_test: {
      url: process.env.TAIKO_TEST_URL || `https://rpc.hekla.taiko.xyz`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    hashkey_test: {
      url:
        process.env.HASHKEY_TEST_URL ||
        `https://hsk-scroll-testnet-rpc.alt.technology`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    mode_test: {
      url: process.env.MODE_TEST_URL || `https://sepolia.mode.network`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    form_test: {
      url: process.env.FORM_TEST_URL || `https://testnet-rpc.form.network/http`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bera_test: {
      url: process.env.BERA_TEST_URL || `https://bartio.rpc.berachain.com/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bera_cArtio: {
      url: process.env.BERA_CARTIO_URL || ``,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    linea_test: {
      url:
        process.env.LINEA_TEST_URL ||
        `https://linea-sepolia.blockpi.network/v1/rpc/public`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bitlayer_test: {
      url: process.env.BITLAYER_TEST_URL || `https://testnet-rpc.bitlayer.org`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    rootstock_test: {
      url:
        process.env.ROOTSTOCK_TEST_URL || `https://public-node.testnet.rsk.co`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    corn_test: {
      url: process.env.CORN_TEST_URL || `https://testnet-rpc.usecorn.com`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    soneium_test: {
      url: process.env.SONEIUM_TEST_URL || `https://rpc.minato.soneium.org`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    monad_test: {
      url: process.env.MONAD_TEST_RPC_URL || `https://rpc.monad.network`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    ink_test: {
      url: process.env.INK_TEST_RPC_URL || `https://rpc-gel-sepolia.inkonchain.com`,
      accounts: PRIVATE_KEY? [PRIVATE_KEY] : [],
    },

    mainnet: {
      url:
        process.env.ETH_URL ||
        `https://mainnet.infura.io/v3/${process.env.INFURA_KEY}`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    polygon: {
      url: "https://polygon-rpc.com/",
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bsc: {
      url: process.env.BSC_URL || `https://bsc-dataseed.binance.org/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    arb: {
      url:
        process.env.ARB_URL ||
        `https://arb.getblock.io/${process.env.GETBLOCK_KEY}/mainnet/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    mantle: {
      url: process.env.MANTLE_TESTNET_URL || `https://rpc.mantle.xyz/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    merlin: {
      url: process.env.MERLIN_URL || ` https://rpc.merlinchain.io`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    ailayer: {
      url: process.env.AILAYER_URL || `https://mainnet-rpc.ailayer.xyz/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    avax: {
      url: process.env.AVAX_URL || `https://api.avax.network/ext/bc/C/rpc`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bob: {
      url: process.env.BOB_URL || `https://rpc.gobob.xyz/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    base: {
      url: process.env.BASE_URL || `https://mainnet.base.org/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    core: {
      url: process.env.CORE_URL || `https://rpc.ankr.com/core`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    taiko: {
      url: process.env.CORE_URL || `https://rpc.mainnet.taiko.xyz`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    mode: {
      url: process.env.CORE_URL || `https://mainnet.mode.network`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    linea: {
      url: process.env.LINEA_URL || `https://rpc.linea.build`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bitlayer: {
      url: process.env.BITLAYER_URL || `https://rpc.bitlayer-rpc.com`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    corn: {
      url: process.env.CORN_URL || `https://maizenet-rpc.usecorn.com`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    sonic: {
      url: process.env.SONIC_URL || `https://rpc.soniclabs.com`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    zksync: {
      url: process.env.ZKSYNC_URL || `https://mainnet.era.zksync.io`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    sei: {
      url: process.env.SEI_URL || `https://evm-rpc.sei-apis.com/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    bera: {
      url: process.env.BERA_URL || `https://rpc.berachain.com/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    rootstock: {
      url: process.env.ROOTSTOCK_URL || `https://public-node.rsk.co`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    soneium: {
      url: process.env.SONEIUM_URL || `https://rpc.soneium.org/`,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
    },
    ink: {
      url: process.env.INK_URL || `https://rpc-gel.inkonchain.com`,
      accounts: PRIVATE_KEY? [PRIVATE_KEY] : [],
    }
  },

  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || "",
      arb: process.env.ARBISCAN_API_KEY || "",
      polygon: process.env.POLYSCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      merlin: process.env.MERLINSCAN_API_KEY || "",
      mantle: "mantle",
      avax: "avax",
      base: process.env.BASESCAN_API_KEY || "",
      taiko: process.env.TAIKOSCAN_API_KEY || "",
      linea: process.env.LINEASCAN_API_KEY || "",
      sonic: process.env.SONICSCAN_API_KEY || "",
      sei: process.env.SEITRACE_API_KEY || "sei",
      bera: process.env.BERASCAN_API_KEY || "",
      rootstock: process.env.ROOTSTOCKSCAN_API_KEY || "rootstock",
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
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org/",
        },
      },
      {
        network: "taiko",
        chainId: 167000,
        urls: {
          apiURL: "https://api.taikoscan.io/api",
          browserURL: "https://taikoscan.io/",
        },
      },
      {
        network: "linea",
        chainId: 59144,
        urls: {
          apiURL: "https://api.lineascan.build/api",
          browserURL: "https://lineascan.build/",
        },
      },
      {
        network: "sonic",
        chainId: 146,
        urls: {
          apiURL: "https://api.sonicscan.org/api",
          browserURL: "https://sonicscan.org/",
        },
      },
      {
        network: "sei",
        chainId: 1329,
        urls: {
          apiURL: "https://seitrace.com/pacific-1/api",
          browserURL: "https://seitrace.com",
        },
      },
      {
        network: "bera",
        chainId: 80094,
        urls: {
          apiURL: "https://api.berascan.com/api",
          browserURL: "https://berascan.com/",
        },
      },
      {
        network: "rootstock",
        chainId: 30,
        urls: {
          apiURL: "https://rootstock.blockscout.com/api/",
          browserURL: "https://rootstock.blockscout.com/",
        },
      },
    ],
  },
};

export default config;
