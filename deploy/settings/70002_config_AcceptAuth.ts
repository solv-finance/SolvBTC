import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { DeployFunction } from 'hardhat-deploy/types'
import { MetaTransactionData, OperationType } from '@safe-global/types-kit';
import { SafeProposer, SafeProposerConfig } from '../helpers/SafeProposer';
import { ethers, network } from 'hardhat';
import { AuthData } from "./70000_export_AuthContracts";
import { getPrivateKey } from '../../hardhat.config';
import colors from "colors";

const iface = new ethers.utils.Interface(AuthData.getAuthAbi());

const SAFE_ADDRESS = AuthData.getAdminByChain(network.name);
//const SIGNER_PRIVATE_KEY = getPrivateKey();

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

type AcceptanceFunctionName = 'acceptAdmin' | 'acceptOwnership';

const proposeAcceptanceTransaction = async function(
  safeProposer: SafeProposer,
  toAddress: string,
  functionName: AcceptanceFunctionName
) {
  const safeTransactionData: MetaTransactionData = {
    to: toAddress,
    value: '0',
    data: iface.encodeFunctionData(functionName),
    operation: OperationType.Call
  };
  await safeProposer.proposeTransaction([safeTransactionData]);
  console.log(`${colors.green(`* ${functionName === 'acceptAdmin' ? 'Admin' : 'Ownership'} acceptance transaction proposed`)}`);
}

const acceptAuth: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  console.log(`${colors.magenta(`*** Start accepting authorization for chain: ${hre.network.name} ***`)}`);
  const SIGNER_PRIVATE_KEY = getPrivateKey();
  const proposer = await createProposer(hre, SAFE_ADDRESS, SIGNER_PRIVATE_KEY!);
  const authContracts = await AuthData.getAuthContracts();

  for (let index = 0; index < authContracts.length; index++) {
    const [name, address, funcName] = authContracts[index];
    console.log(`${colors.blue(`<< ${name} Authorization Acceptance (${address}) >>`)}`);
    if (address) {
      const contract = new ethers.Contract(address, AuthData.getAuthAbi(), hre.ethers.provider);
      try {
        const isOwnershipTransfer = funcName === "transferOwnership";
        const pendingRole = isOwnershipTransfer ? await contract.pendingOwner() : await contract.pendingAdmin();
        const acceptFunction = isOwnershipTransfer ? 'acceptOwnership' : 'acceptAdmin';

        console.log(`${colors.blue(`Current pending ${isOwnershipTransfer ? 'owner' : 'admin'}: ${pendingRole}`)}`);

        if (pendingRole === SAFE_ADDRESS) {
          await proposeAcceptanceTransaction(proposer, address, acceptFunction);
        } else {
          console.log(`${colors.yellow(`* Operation skipped: Pending ${isOwnershipTransfer ? 'owner' : 'admin'} (${pendingRole}) does not match safe address`)}`);
        }
      } catch (error: unknown) {
        const errorMessage = error instanceof Error ? error.message : 'Unknown error';
        console.log(`${colors.red(`* Error processing ${name}: ${errorMessage}`)}`);
      }
      await new Promise(resolve => setTimeout(resolve, 2000));
    } else {
      console.log(`${colors.yellow(`* ${name}: Contract not deployed - Operation skipped`)}`);
    }
  }
}

acceptAuth.tags = ["AcceptAuth"];
export default acceptAuth;
