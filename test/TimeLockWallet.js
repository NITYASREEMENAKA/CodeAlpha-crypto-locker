const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("TimeLockWallet", function () {
  let wallet, owner, user1;
  const ETH_TOKEN = "0x0000000000000000000000000000000000000000";

  beforeEach(async function () {
    [owner, user1] = await ethers.getSigners();
    const Wallet = await ethers.getContractFactory("TimeLockWallet");
    wallet = await Wallet.deploy();
    await wallet.waitForDeployment();
  });

  it("should accept an ETH deposit with a lock time", async function () {
    const lockSeconds = 120; // 2 minutes
    await wallet.connect(user1).depositETH(lockSeconds, {
      value: ethers.parseEther("1"),
    });

    const deposit = await wallet.getDeposit(user1.address, ETH_TOKEN);
    expect(deposit.amount).to.equal(ethers.parseEther("1"));
  });

  it("should BLOCK withdrawal before unlock time (early withdrawal test)", async function () {
    await wallet.connect(user1).depositETH(120, {
      value: ethers.parseEther("1"),
    });

    // Try withdrawing immediately -> must revert
    await expect(wallet.connect(user1).withdrawETH()).to.be.revertedWithCustomError(
      wallet,
      "StillLocked"
    );
  });

  it("should ALLOW withdrawal after unlock time has passed", async function () {
    await wallet.connect(user1).depositETH(120, {
      value: ethers.parseEther("1"),
    });

    // Fast-forward blockchain time by 121 seconds
    await time.increase(121);

    const balanceBefore = await ethers.provider.getBalance(user1.address);
    const tx = await wallet.connect(user1).withdrawETH();
    const receipt = await tx.wait();
    const gasUsed = receipt.gasUsed * receipt.gasPrice;
    const balanceAfter = await ethers.provider.getBalance(user1.address);

    expect(balanceAfter).to.equal(
      balanceBefore + ethers.parseEther("1") - gasUsed
    );

    const deposit = await wallet.getDeposit(user1.address, ETH_TOKEN);
    expect(deposit.amount).to.equal(0);
  });

  it("should revert withdraw if user has nothing deposited", async function () {
    await expect(wallet.connect(user1).withdrawETH()).to.be.revertedWithCustomError(
      wallet,
      "NothingToWithdraw"
    );
  });
});
