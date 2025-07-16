import { deployments, network } from 'hardhat';

const SolvBTCInfos = require("../SolvBTC/10099_export_SolvBTCInfos");
const SolvBTCV3Infos = require("../SolvBTC/10399_export_SolvBTCV3Infos");
const LstInfos = require("../SolvBTCYieldToken/20099_export_SolvBTCYTInfos");
const LstV3Infos = require("../SolvBTCYieldToken/20399_export_SolvBTCYTV3Infos");

export type AuthContractConfig = [string, string | undefined, string];

export class AuthData {
  public static async getAuthContracts(): Promise<AuthContractConfig[]> {
    return [
      ["SolvBTCFactory", SolvBTCInfos.SolvBTCFactoryAddresses[network.name], "transferAdmin"],
      ["SolvBTCYieldTokenFactory", LstInfos.SolvBTCYieldTokenFactoryAddresses[network.name], "transferAdmin"],
      ["SolvBTCFactoryV3", SolvBTCV3Infos.SolvBTCFactoryV3Addresses[network.name], "transferAdmin"],
      ["SolvBTCYieldTokenFactoryV3", LstV3Infos.SolvBTCYieldTokenFactoryV3Addresses[network.name], "transferAdmin"],
      ["SolvBTCMultiAssetPool", SolvBTCInfos.SolvBTCMultiAssetPoolAddresses[network.name], "transferAdmin"],
      ["SolvBTCYieldTokenOracleForSFT", (await deployments.getOrNull("SolvBTCYieldTokenOracleForSFTProxy"))?.address, "transferAdmin"],
      ["SolvBTCRouter", (await deployments.getOrNull("SolvBTCRouterProxy"))?.address, "transferAdmin"],
      ["SolvBTCRouterV2", (await deployments.getOrNull("SolvBTCRouterV2Proxy"))?.address, "transferOwnership"],
      ["XSolvBTCPool", (await deployments.getOrNull("XSolvBTCPoolProxy"))?.address, "transferAdmin"],
      ["XSolvBTCOracle", (await deployments.getOrNull("XSolvBTCOracleProxy"))?.address, "transferAdmin"],
      ["OpenFundMarket", SolvBTCInfos.OpenFundMarketAddresses[network.name], "setPendingAdmin"],
    ];
  }

  public static getAuthAbi(): string[] {
    return [
      "function admin() view returns (address)",
      "function pendingAdmin() view returns (address)",
      "function setPendingAdmin(address newAdmin) external",  // v1
      "function transferAdmin(address newAdmin) external",  // v2
      "function acceptAdmin() external",

      "function owner() view returns (address)",
      "function pendingOwner() view returns (address)",
      "function transferOwnership(address newOwner) external",
      "function acceptOwnership() external",

      "function DEFAULT_ADMIN_ROLE() view returns (bytes32)",
      "function hasRole(bytes32 role, address account) view returns (bool)",
      "function grantRole(bytes32 role, address account) external",
      "function renounceRole(bytes32 role, address account) external",
    ];
  }

  public static getAdminByChain(chainName: string) {
    const defaultAdmin: string = "0x0c2Bc4d2698820e12E6eBe863E7b9E2650CD5b7D";
    const customAdmins: { [key: string]: string } = {
      soneium: "0x6DDb2894cb7C33A271B89dE76e1f9e0eb78a6BdC",
    };
    return customAdmins[chainName] || defaultAdmin;
  }
}