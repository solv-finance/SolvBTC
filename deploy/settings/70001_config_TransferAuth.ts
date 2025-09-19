import colors from "colors";
import { ethers } from "hardhat";
import { AuthData } from "./70000_export_AuthContracts";
import { DeployFunction } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const { txWait } = require("../utils/deployUtils");

async function transferAdmin(contractAddress: string, newAdmin: string, funcName: "setPendingAdmin" | "transferAdmin") {
  const deployer = (await ethers.getSigners())[0];
  const contract = new ethers.Contract(contractAddress, AuthData.getAuthAbi(), deployer);
  const currentAdmin = await contract.admin();
  const currentPendingAdmin = await contract.pendingAdmin();
  console.log(`* Current Status:\n  - Admin: ${currentAdmin}\n  - Pending: ${currentPendingAdmin}\n  - Target: ${newAdmin}`);
  if (currentAdmin == newAdmin || currentPendingAdmin == newAdmin) {
    console.log(colors.yellow(`* Operation skipped: Admin already set to target value`));
  } else if (currentAdmin != deployer.address) {
    console.log(colors.red(`* Operation failed: Current admin ${currentAdmin} does not match deployer ${deployer.address}`));
  } else {
    const tx = await contract[funcName](newAdmin);
    console.log(`* Transferring admin to ${newAdmin} at tx ${tx.hash}`);
    await txWait(tx);
  }
}

async function transferOwnership(contractAddress: string, newOwner: string) {
  const deployer = (await ethers.getSigners())[0];
  const contract = new ethers.Contract(contractAddress, AuthData.getAuthAbi(), deployer);
  const currentOwner = await contract.owner();
  const currentPendingOwner = await contract.pendingOwner();
  console.log(`* Current Status:\n  - Owner: ${currentOwner}\n  - Pending: ${currentPendingOwner}\n  - Target: ${newOwner}`);
  if (currentOwner == newOwner || currentPendingOwner == newOwner) {
    console.log(colors.yellow(`* Operation skipped: Owner already set to target value`));
  } else if (currentOwner != deployer.address) {
    console.log(colors.red(`* Operation failed: Current owner ${currentOwner} does not match deployer ${deployer.address}`));
  } else {
    const tx = await contract.transferOwnership(newOwner);
    console.log(`* Transferring ownership to ${newOwner} at tx ${tx.hash}`);
    await txWait(tx);
  }
}

const transferAuth: DeployFunction = async function(hre: HardhatRuntimeEnvironment) {
  console.log(`${colors.magenta(`*** Start transferring authorization for chain: ${hre.network.name} ***`)}`);
  const authContracts = await AuthData.getAuthContracts();
  const newAdmin = AuthData.getAdminByChain(hre.network.name);

  for (let authContract of authContracts) {
    const [name, address, funcName] = authContract;
    console.log(`${colors.blue(`<< ${name} Authorization Check (${address}) >>`)}`);
    if (address) {
      if (funcName == "transferOwnership") {
        await transferOwnership(address, newAdmin);
      } else if (funcName == "setPendingAdmin" || funcName == "transferAdmin") {
        await transferAdmin(address, newAdmin, funcName);
      } else {
        console.log(`${colors.red(`* Invalid func name`)}`);
      }
    } else {
      console.log(`* ${name} not deployed, ignored`);
    }
  }
};

transferAuth.tags = ["TransferAuth"];
export default transferAuth;