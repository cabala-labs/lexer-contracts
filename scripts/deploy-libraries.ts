import { ethers } from "hardhat";

async function deployLibraries() {
  const TokenLibs = await ethers.getContractFactory("TokenLibs");
  const tokenLibs = await TokenLibs.deploy();

  await tokenLibs.deployed();

  console.log("TokenLibs deployed to:", tokenLibs.address);

  return tokenLibs.address;
}

export { deployLibraries };
