import { ethers } from "hardhat";

async function main() {
  const AccessControl = await ethers.getContractFactory("AccessControl");
  const accessControl = await AccessControl.deploy("Hello, Hardhat!");

  await accessControl.deployed();

  console.log("AccessControl deployed to:", accessControl.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
