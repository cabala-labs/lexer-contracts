import { ethers } from "hardhat";

async function deployDiamondToken() {
  const DiamondToken = await ethers.getContractFactory("Diamond");
  const diamondToken = await DiamondToken.deploy();

  await diamondToken.deployed();

  console.log("Diamond deployed to:", diamondToken.address);

  return diamondToken.address;
}

async function deployPool(diamondAddress: string, tokenPriceAddress: string) {
  const DiamondPool = await ethers.getContractFactory("DiamondPool");
  const diamondPool = await DiamondPool.deploy(diamondAddress, tokenPriceAddress);

  await diamondPool.deployed();

  console.log("DiamondPool deployed to:", diamondPool.address);

  return diamondPool.address;
}

async function deploySwap(poolAddress: string, tokenPriceAddress: string) {
  const DiamondSwap = await ethers.getContractFactory("DiamondSwap");
  const diamondSwap = await DiamondSwap.deploy(poolAddress, tokenPriceAddress);

  await diamondSwap.deployed();

  console.log("DiamondSwap deployed to:", diamondSwap.address);

  return diamondSwap.address;
}

async function deployTrade(poolAddress: string, tokenPriceAddress: string) {
  const DiamondTrade = await ethers.getContractFactory("DiamondTrade");
  const diamondTrade = await DiamondTrade.deploy(poolAddress, tokenPriceAddress);

  await diamondTrade.deployed();

  console.log("DiamondTrade deployed to:", diamondTrade.address);

  return diamondTrade.address;
}

async function deployDiamond(tokenPriceAddress: string) {
  const diamondTokenAddress = await deployDiamondToken();

  const poolAddress = await deployPool(diamondTokenAddress, tokenPriceAddress);

  await deploySwap(poolAddress, tokenPriceAddress);
  await deployTrade(poolAddress, tokenPriceAddress);
}

export { deployDiamond };
