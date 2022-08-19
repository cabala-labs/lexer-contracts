import { ethers } from "hardhat";

async function deployTokenPrice(accessControlAddress: string) {
  const TokenPrice = await ethers.getContractFactory("TokenPrice");
  const tokenPrice = await TokenPrice.deploy(accessControlAddress);

  await tokenPrice.deployed();

  console.log("TokenPrice deployed to:", tokenPrice.address);

  return tokenPrice.address;
}

export { deployTokenPrice };
