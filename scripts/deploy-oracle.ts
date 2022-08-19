import { ethers } from "hardhat";

async function main() {
  const TokenPrice = await ethers.getContractFactory("TokenPrice");
  const tokenPrice = await TokenPrice.deploy("Hello, Hardhat!");

  await tokenPrice.deployed();

  console.log("TokenPrice deployed to:", tokenPrice.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
