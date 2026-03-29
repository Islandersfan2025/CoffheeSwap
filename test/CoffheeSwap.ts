import { expect } from "chai";
import hre from "hardhat";

describe("CoffheeSwap", function () {
  async function deployFixture() {
    const [owner, user] = await hre.ethers.getSigners();

    const MockToken = await hre.ethers.getContractFactory("MockConfidentialERC7984Like");
    const tokenA = await MockToken.deploy("Token A", "TKNA", 18);
    await tokenA.waitForDeployment();

    const tokenB = await MockToken.deploy("Token B", "TKNB", 18);
    await tokenB.waitForDeployment();

    const CoffheeSwap = await hre.ethers.getContractFactory("CoffheeSwap");
    const swap = await CoffheeSwap.deploy(
      await tokenA.getAddress(),
      await tokenB.getAddress(),
      2, // A -> B numerator
      1, // A -> B denominator
      1, // B -> A numerator
      2, // B -> A denominator
      owner.address
    );
    await swap.waitForDeployment();

    return { owner, user, tokenA, tokenB, swap };
  }

  it("deploys with the correct token addresses and rates", async function () {
    const { tokenA, tokenB, swap } = await deployFixture();

    expect(await swap.tokenA()).to.equal(await tokenA.getAddress());
    expect(await swap.tokenB()).to.equal(await tokenB.getAddress());

    expect(await swap.rateAToBNumerator()).to.equal(2);
    expect(await swap.rateAToBDenominator()).to.equal(1);
    expect(await swap.rateBToANumerator()).to.equal(1);
    expect(await swap.rateBToADenominator()).to.equal(2);
  });

  it("owner can update rates", async function () {
    const { swap } = await deployFixture();

    await expect(swap.setRates(3, 1, 1, 3))
      .to.emit(swap, "RatesUpdated")
      .withArgs(3, 1, 1, 3);

    expect(await swap.rateAToBNumerator()).to.equal(3);
    expect(await swap.rateAToBDenominator()).to.equal(1);
    expect(await swap.rateBToANumerator()).to.equal(1);
    expect(await swap.rateBToADenominator()).to.equal(3);
  });

  it("non-owner cannot update rates", async function () {
    const { swap, user } = await deployFixture();

    await expect(
      swap.connect(user).setRates(3, 1, 1, 3)
    ).to.be.reverted;
  });
});