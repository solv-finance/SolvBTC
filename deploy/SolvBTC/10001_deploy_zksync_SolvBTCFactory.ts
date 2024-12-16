import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const admin = deployer;
  const governor = deployer;

  const instance = await deploy("SolvBTCFactory", {
    contract: "SolvBTCFactory",
    from: deployer,
    log: true,
    args: [admin, governor],
  });
  console.log("SolvBTCFactory deployed to:", instance.address);

  const artifact = await hre.artifacts.readArtifact("SolvBTCFactory");
  await deployments.save("SolvBTCFactory", {
    address: instance.address,
    abi: artifact.abi,
    bytecode: artifact.bytecode,
    deployedBytecode: artifact.deployedBytecode,
  });

  // verify contracts
  await hre.run("verify:verify", {
    address: instance.address,
    constructorArguments: [admin, governor],
  });
};
export default func;
