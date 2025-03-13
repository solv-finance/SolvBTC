const colors = require("colors");
const { getSigner } = require("./deployUtils");
const {
  makeValidateImplementation,
} = require("@openzeppelin/hardhat-upgrades/dist/validate-implementation");

const ProxyAdmin = require("@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol/ProxyAdmin.json");
const TransparentUpgradeableProxy = require("@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json");

const deployProxyAdmin = async (opts) => {
  const { deployments } = hre;
  const { deploy } = deployments;
  return await deploy("ProxyAdmin", {
    contract: ProxyAdmin,
    from: opts.from,
    gasPrice: opts.gasPrice,
    log: true,
  });
};

const deployOrUpgrade = async (
  firstImplName,
  proxyName,
  opts,
  { initializer, postUpgrade, upgrades }
) => {
  const newImpl = await deployOrUpgradeImplemention(firstImplName, opts, {
    upgrades: upgrades.slice(0),
  });
  const newImplName =
    upgrades && upgrades.length > 0
      ? upgrades[upgrades.length - 1]
      : firstImplName;

  const { proxy } = await deployOrUpgradeProxy(firstImplName, proxyName, opts, {
    initializer: initializer,
    postUpgrade: postUpgrade,
    upgrades: upgrades.slice(0),
  });
  console.log(
    ` INFO: ${colors.yellow(proxyName)} deployed at ${colors.green(
      proxy.address
    )} point to ${colors.yellow(newImplName)} at ${colors.green(
      newImpl.address
    )} on ${colors.red(network.name)}`
  );
  return { proxy, newImpl, newImplName };
};

const deployOrUpgradeImplemention = async (
  firstImplName,
  opts,
  { upgrades }
) => {
  const { deployments } = hre;
  const { deploy } = deployments;

  let firstImpl = await deployments.getOrNull(firstImplName);
  if (!firstImpl) {
    firstImpl = await deploy(firstImplName, opts);
    console.log(
      ` INFO: ${colors.yellow(`${firstImplName}`)} deployed at ${colors.green(
        firstImpl.address
      )} on ${colors.red(network.name)}`
    );
  }

  let lastImpl = firstImpl;
  if (upgrades && upgrades.length > 0) {
    let newImplName = upgrades.pop();
    upgrades.forEach(async (upgrade) => {
      await deployments.get(upgrade);
    });

    // const contractFactory = await ethers.getContractFactory(opts.contract);
    // const validateImplementation = makeValidateImplementation(hre);
    // validateImplementation(contractFactory, {
    //   kind: 'transparent',
    //   unsafeAllowCustomTypes: false,
    //   unsafeAllowLinkedLibraries: false,
    // });

    const newImpl = await deploy(newImplName, opts);
    console.log(
      ` INFO: ${colors.yellow(`${newImplName}`)} deployed at ${colors.green(
        newImpl.address
      )} on ${colors.red(network.name)}`
    );
    lastImpl = newImpl;
  }
  return lastImpl;
};

const deployOrUpgradeProxy = async (
  firstImplName,
  proxyName,
  opts,
  { initializer, postUpgrade, upgrades }
) => {
  const { deployments } = hre;
  const { deploy } = deployments;

  let proxyAdmin = await deployments.getOrNull("ProxyAdmin");
  if (!proxyAdmin) {
    proxyAdmin = await deployProxyAdmin(opts);
    console.log(
      ` INFO: ${colors.yellow(`ProxyAdmin`)} deployed at ${colors.green(
        proxyAdmin.address
      )} on ${colors.red(network.name)}`
    );
  }

  let firstImpl = await deployments.get(firstImplName);
  let newImpl = firstImpl;

  let proxy = await deployments.getOrNull(proxyName);
  if (!proxy) {
    const initData = getInitializerData(
      await ethers.getContractFactory(opts.contract),
      initializer && initializer.args ? initializer.args : [],
      initializer ? initializer.method : false
    );
    console.log(`initData: ${initData}`);

    proxy = await deploy(proxyName, {
      contract: TransparentUpgradeableProxy,
      from: opts.from,
      gasPrice: opts.gasPrice,
      log: true,
      args: [firstImpl.address, proxyAdmin.address, initData],
    });
  }

  if (upgrades && upgrades.length > 0) {
    let newImplName = upgrades.pop();
    let previousImplName = upgrades.length > 0 ? upgrades.pop() : firstImplName;

    if (previousImplName === newImplName) {
      throw new Error("Implementation version not changed, can't upgrade.");
    }

    const signer = await getSigner(opts.from);
    const proxyAdminContract = await ethers.getContractAt(
      proxyAdmin.abi,
      proxyAdmin.address,
      signer
    );
    const actualImpl = await proxyAdminContract.getProxyImplementation(
      proxy.address
    );
    const previousImpl = await deployments.get(previousImplName);
    newImpl = await deployments.get(newImplName);
    console.log(
      `actualImpl: ${actualImpl}, previousImpl ${previousImpl.address}, newImpl: ${newImpl.address}`
    );

    if (actualImpl == previousImpl.address) {
      console.log(`Upgrading from ${previousImplName} to ${newImplName}`);
      if (postUpgrade && postUpgrade.method && postUpgrade.args) {
        const upgradeData = getInitializerData(
          await ethers.getContractFactory(opts.contract),
          postUpgrade.args,
          postUpgrade.method
        );
        await proxyAdminContract.upgradeAndCall(
          proxy.address,
          newImpl.address,
          upgradeData,
          { gasPrice: opts.gasPrice }
        );
      } else {
        await proxyAdminContract.upgrade(proxy.address, newImpl.address, {
          gasPrice: opts.gasPrice,
        });
      }
    } else if (actualImpl == newImpl.address) {
      console.log("Implementation not changed, IGNORE");
    } else {
      throw new Error(`Proxy is actually pointing to: ${actualImpl}`);
    }
  }
  return { proxy, newImpl };
};

const getInitializerData = (ImplFactory, args = [], initializer) => {
  if (initializer === false) {
    return "0x";
  }
  const allowNoInitialization = initializer === undefined && args.length === 0;
  initializer = initializer || "initialize";
  try {
    const fragment = ImplFactory.interface.getFunction(initializer);
    return ImplFactory.interface.encodeFunctionData(fragment, args);
  } catch (e) {
    if (e instanceof Error) {
      if (allowNoInitialization && e.message.includes("no matching function")) {
        return "0x";
      }
    }
    throw e;
  }
};

module.exports = {
  deployOrUpgrade,
  deployOrUpgradeImplemention,
  deployOrUpgradeProxy,
};
