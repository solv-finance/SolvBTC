import SafeApiKit from '@safe-global/api-kit';
import Safe, { CreateTransactionProps } from '@safe-global/protocol-kit';
import { MetaTransactionData, OperationType } from '@safe-global/types-kit';

export interface SafeProposerConfig {
  safeApiKey: string;
  chainId: bigint;
  rpcUrl: string;
  safeAddress: string;
  senderAddress: string;
  senderPrivateKey: string;
}

export class SafeProposer {
  public config: SafeProposerConfig;

  constructor(config: SafeProposerConfig) {
    this.config = config;
  }

  /**
   * Get the next nonce of the safe wallet, ignoring all pending transactions
   */
  public async getNonce(safeAddress: string): Promise<number> {
    const safeProtocolKit = await Safe.init({
      provider: this.config.rpcUrl,
      safeAddress: safeAddress
    });
    const nonce = await safeProtocolKit.getNonce();
    return nonce;
  }

  public async proposeTransaction(safeTransactionData: MetaTransactionData[]) {
    const { safeApiKey, chainId, rpcUrl, safeAddress, senderAddress, senderPrivateKey } = this.config;
    const apiKit = new SafeApiKit({
      chainId: chainId,
      apiKey: safeApiKey
    });
    const safeProtocolKit = await Safe.init({
      provider: rpcUrl,
      signer: senderPrivateKey,
      safeAddress: safeAddress
    });
    // get the next nonce of the safe wallet, considering all pending transactions
    const nextNonce = await apiKit.getNextNonce(safeAddress);
    const safeTransaction = await safeProtocolKit.createTransaction({
      transactions: safeTransactionData,
      options: {
        nonce: Number(nextNonce),
      }
    });
    const safeTxHash = await safeProtocolKit.getTransactionHash(safeTransaction);
    const signature = await safeProtocolKit.signHash(safeTxHash);
    await apiKit.proposeTransaction({
      safeAddress: safeAddress,
      safeTransactionData: safeTransaction.data,
      safeTxHash: safeTxHash,
      senderAddress: senderAddress,
      senderSignature: signature.data
    });
  }

}