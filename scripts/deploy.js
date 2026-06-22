const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying TimeLockWallet with account:", deployer.address);

  const TimeLockWallet = await hre.ethers.getContractFactory("TimeLockWallet");
  const wallet = await TimeLockWallet.deploy();
  await wallet.waitForDeployment();

  console.log("TimeLockWallet deployed to:", await wallet.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
