import hre from "hardhat";
import { Encryptable } from "@cofhe/sdk";

async function main() {
  const [signer] = await hre.ethers.getSigners();
  console.log("Signer:", signer.address);

  const swapAddress = "0xYourSwapAddress";

  const swap = await hre.ethers.getContractAt(
    "CoffheeSwap",
    swapAddress,
    signer
  );

  // Creates a client configured for the current network/signer
  const cofheClient = await hre.cofhe.createClientWithBatteries(signer);

  // Encrypt a 64-bit token amount, e.g. 100 units
  const [encryptedAmountIn] = await cofheClient
    .encryptInputs([Encryptable.uint64(100n)])
    .execute();

  const tx = await swap.swapAForB(encryptedAmountIn);
  await tx.wait();

  console.log("swapAForB confirmed");
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});