import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import TransparentUpgradeableProxy from "@openzeppelin/upgrades-core/artifacts/@openzeppelin/contracts-v5/proxy/transparent/TransparentUpgradeableProxy.sol/TransparentUpgradeableProxy.json";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;

  const IMPLEMENTATION_SLOT =
    "0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC";

  const artifact = await hre.artifacts.readArtifact(
    "SolvBTCYieldTokenOracleForSFT"
  );
  const oracleFactory = await hre.ethers.getContractFactory(
    "SolvBTCYieldTokenOracleForSFT"
  );

  const oracle = await hre.upgrades.deployProxy(oracleFactory, [], {
    initializer: "initialize",
  });
  await oracle.waitForDeployment();

  const oracleAddress = await oracle.getAddress();
  console.log(
    "SolvBTCYieldTokenOracleForSFT proxy deployed to:",
    oracleAddress
  );

  await deployments.save("SolvBTCYieldTokenOracleForSFTProxy", {
    address: oracleAddress,
    abi: TransparentUpgradeableProxy.abi,
    bytecode: TransparentUpgradeableProxy.bytecode,
    deployedBytecode: TransparentUpgradeableProxy.deployedBytecode,
  });

  const implAddressHex = await hre.ethers.provider.getStorage(
    oracleAddress,
    IMPLEMENTATION_SLOT
  );
  const implAddress = "0x" + implAddressHex.slice(-40);
  console.log(`Implementation address: ${implAddress}`);

  await deployments.save("SolvBTCYieldTokenOracleForSFTImpl", {
    address: implAddress,
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    deployedBytecode: artifact.deployedBytecode,
  });

  // verify contracts
  await hre.run("verify:verify", {
    address: oracleAddress,
  });
  await hre.run("verify:verify", {
    address: implAddress,
  });
};
export default func;
