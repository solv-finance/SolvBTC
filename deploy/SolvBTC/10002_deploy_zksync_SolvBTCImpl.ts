import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const version = "_v2.0";

  const instance = await deploy("SolvBTC" + version, {
    contract: "SolvBTC",
    from: deployer,
    log: true,
  });
  console.log("SolvBTC impl deployed to:", instance.address);

  const artifact = await hre.artifacts.readArtifact("SolvBTC");
  await deployments.save("SolvBTC" + version, {
    address: instance.address,
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    deployedBytecode: artifact.deployedBytecode,
  });

  // verify contracts
  await hre.run("verify:verify", {
    address: instance.address,
    constructorArguments: [],
  });
};
export default func;
