# SolvBTC

## Description of Business

[Introducing SolvBTC, The First-Ever Yield Bearing Bitcoin](https://medium.com/@solvprotocol/introducing-solvbtc-the-first-ever-yield-bearing-bitcoin-871179c73ca6)

[Solv Protocol Partners with Antalpha To Enhance Security for SolvBTC](https://medium.com/@solvprotocol/solv-protocol-partners-with-antalpha-to-enhance-security-for-solvbtc-18f0bb5cd41f)

## Test

You can test by forking arbitrum mainnet
```bash
export ARB_RPC_URL=# Arbitrum archive node RPC URL
anvil --fork-url $ARB_RPC_URL --fork-block-number 209324475
 export FOUNDRY_ETH_RPC_URL=http://127.0.0.1:8545
forge test
```
