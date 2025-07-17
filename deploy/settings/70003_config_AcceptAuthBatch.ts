import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types'
import { MetaTransactionData, OperationType } from '@safe-global/types-kit';
import { SafeProposer, SafeProposerConfig } from '../helpers/SafeProposer';
import { ethers, network } from 'hardhat';
import { Contract } from 'ethers';
import { AuthData } from "./70000_export_AuthContracts";
import { getPrivateKey } from '../../hardhat.config';
import colors from "colors";

const iface = new ethers.utils.Interface(AuthData.getAuthAbi());

const SAFE_ADDRESS = AuthData.getAdminByChain(network.name);
const SIGNER_PRIVATE_KEY = getPrivateKey();

const createProposer = async function(hre: HardhatRuntimeEnvironment, safeAddress: string, signerKey: string): Promise<SafeProposer> {
  const signer = new ethers.Wallet(signerKey, hre.ethers.provider);

  const proposerConfig: SafeProposerConfig = {
    safeApiKey: process.env.SAFE_API_KEY!,
    chainId: BigInt(await hre.getChainId()),
    rpcUrl: hre.network.config.url,
    safeAddress: safeAddress,
    senderAddress: signer.address,
    senderPrivateKey: signerKey,
  };
  return new SafeProposer(proposerConfig);
}

const createAcceptanceTransaction = async (contract: Contract, address: string, name: string, funcName: string): Promise<MetaTransactionData | null> => {
  const isOwnershipTransfer = funcName === "transferOwnership";
  const pendingRole = isOwnershipTransfer ? await contract.pendingOwner() : await contract.pendingAdmin();
  const acceptFunction = isOwnershipTransfer ? 'acceptOwnership' as const : 'acceptAdmin' as const;

  console.log(`${colors.blue(`Current pending ${isOwnershipTransfer ? 'owner' : 'admin'}: ${pendingRole}`)}`);

  if (pendingRole === SAFE_ADDRESS) {
    console.log(`${colors.green(`Accepting ${isOwnershipTransfer ? 'ownership' : 'admin'} on ${name} - ${address}`)}`);
    return {
      to: address,
      value: '0',
      data: iface.encodeFunctionData(acceptFunction),
      operation: OperationType.Call
    };
  } else {
    console.log(`${colors.yellow(`* Operation skipped: Pending ${isOwnershipTransfer ? 'owner' : 'admin'} (${pendingRole}) does not match safe address`)}`);
    return null;
  }
};

const acceptAuthBatch: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  console.log(`${colors.magenta(`*** Start accepting authorization for chain: ${hre.network.name} ***`)}`);
  try {
    const proposer = await createProposer(hre, SAFE_ADDRESS, SIGNER_PRIVATE_KEY!);
    const authContracts = await AuthData.getAuthContracts();

    const safeTransactionData: MetaTransactionData[] = [];
    for (let index = 0; index < authContracts.length; index++) {
      let [name, address, funcName] = authContracts[index];
      console.log(`${colors.blue(`<< ${name} Authorization Acceptance (${address}) >>`)}`);
      if (address) {
        const contract = new ethers.Contract(address, AuthData.getAuthAbi(), hre.ethers.provider);
        try {
          if (funcName === "transferOwnership" || funcName === "setPendingAdmin" || funcName === "transferAdmin") {
            const tx = await createAcceptanceTransaction(contract, address, name, funcName);
            if (tx) safeTransactionData.push(tx);
          } else {
            console.log(`${colors.red(`* Invalid function name: ${funcName}`)}`);
          }
        } catch (error: unknown) {
          const errorMessage = error instanceof Error ? error.message : 'Unknown error';
          console.log(`${colors.red(`* Error processing ${name}: ${errorMessage}`)}`)
        }
      } else {
        console.log(`${colors.yellow(`* ${name}: Contract not deployed - Operation skipped`)}`);
      }
    }

    if (safeTransactionData.length > 0) {
      await proposer.proposeTransaction(safeTransactionData);
      console.log(`${colors.green(`* Authorization acceptance transactions proposed`)}`);
    } else {
      console.log(`${colors.yellow(`* No authorization acceptance transactions to propose`)}`);
    }
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.log(`${colors.red(`* Error in batch processing: ${errorMessage}`)}`);
    throw error;
  }
}

acceptAuthBatch.tags = ["AcceptAuthBatch"];
export default acceptAuthBatch;
