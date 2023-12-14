const getSigner = async (address) => {
  const signers = await hre.ethers.getSigners()
  return signers.find(signer => signer.address === address)
}

const txWait = async (tx) => {
  while (true) {
    let receipt = await tx.wait();
    if (receipt.status || receipt.status == '0x1') {
      break;
    }
  }
}

module.exports = {
  getSigner,
  txWait,
}
