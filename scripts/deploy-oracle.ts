import { ethers } from "hardhat";

async function main() {
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.deploy();

  await simplePriceFeed.deployed();

  console.log(`simplePriceFeedAddress: "${simplePriceFeed.address}",`);

  return { simplePriceFeedAddress: simplePriceFeed.address };
}

export default main;
