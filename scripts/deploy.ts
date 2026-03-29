import hre from "hardhat";

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  const deployerAddress = await deployer.getAddress();

  // Replace these with real deployed token addresses
  const tokenA = "0x1234567890abcdef1234567890abcdef12345678";
  const tokenB = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd";

  console.log("Deploying from:", deployerAddress);
  console.log("tokenA:", tokenA);
  console.log("tokenB:", tokenB);

  const Factory = await hre.ethers.getContractFactory("CoffheeSwap");

  const swap = await Factory.deploy(
    tokenA,
    tokenB,
    2,
    1,
    1,
    2,
    deployerAddress
  );

  await swap.waitForDeployment();
  console.log("Deployed to:", await swap.getAddress());
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});