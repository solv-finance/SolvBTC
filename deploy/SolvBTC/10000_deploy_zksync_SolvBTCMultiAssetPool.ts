import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import TransparentUpgradeableProxy from "@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts-v5/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const IMPLEMENTATION_SLOT =
    "0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC";

  const artifact = await hre.artifacts.readArtifact("SolvBTCMultiAssetPool");
  const solvBTCMultiAssetPoolFactory = await hre.ethers.getContractFactory(
    "SolvBTCMultiAssetPool"
  );

  const solvBTCMultiAssetPool = await hre.upgrades.deployProxy(
    solvBTCMultiAssetPoolFactory,
    [],
    { initializer: "initialize" }
  );
  await solvBTCMultiAssetPool.waitForDeployment();

  const solvBTCMultiAssetPoolAddress = await solvBTCMultiAssetPool.getAddress();
  console.log(
    "SolvBTCMultiAssetPool proxy deployed to:",
    solvBTCMultiAssetPoolAddress
  );

  await deployments.save("SolvBTCMultiAssetPoolProxy", {
    address: solvBTCMultiAssetPoolAddress,
    abi: TransparentUpgradeableProxy.abi,
    bytecode: TransparentUpgradeableProxy.bytecode,
    deployedBytecode: TransparentUpgradeableProxy.deployedBytecode,
  });

  const implAddressHex = await hre.ethers.provider.getStorage(
    solvBTCMultiAssetPoolAddress,
    IMPLEMENTATION_SLOT
  );
  const implAddress = "0x" + implAddressHex.slice(-40);
  console.log(`Implementation address: ${implAddress}`);

  await deployments.save("SolvBTCMultiAssetPoolImpl", {
    address: implAddress,
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    deployedBytecode: artifact.deployedBytecode,
  });

  /** verify contracts */
  await hre.run("verify:verify", {
    address: solvBTCMultiAssetPoolAddress,
  });
  await hre.run("verify:verify", {
    address: implAddress,
  });
};
export default func;
