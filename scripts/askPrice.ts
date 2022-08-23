import { ethers } from "hardhat";

async function askTokenPrice() {
  const TokenPrice = await ethers.getContractFactory("TokenPrice");
  const tokenPrice = await TokenPrice.attach("0xAF724455Ad5eC5136C98127ecb7046A4538F263B");

  console.log("token price", await tokenPrice.tokens("0x42285Cf0cf215ed9cAAc31825b537109D3938f81"));
}

askTokenPrice().then();
