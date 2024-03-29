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

const getInitializerData = (ImplFactory, args = [], initializer) => {
  if (initializer === false) {
    return "0x"
  }
  const allowNoInitialization = initializer === undefined && args.length === 0
  initializer = initializer || "initialize"
  try {
    const fragment = ImplFactory.interface.getFunction(initializer)
    return ImplFactory.interface.encodeFunctionData(fragment, args)
  } catch (e) {
    if (e instanceof Error) {
      if (allowNoInitialization && e.message.includes("no matching function")) {
        return "0x"
      }
    }
    throw e
  }
}

module.exports = {
  getSigner,
  txWait,
  getInitializerData,
}
