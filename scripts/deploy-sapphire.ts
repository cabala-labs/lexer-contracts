import { ethers } from "hardhat";

async function main(simplePriceFeedAddress: string) {
  const SapphireToken = await ethers.getContractFactory("SapphireToken");
  const sapphireToken = await SapphireToken.deploy();
  await sapphireToken.deployed();

  const SapphirePool = await ethers.getContractFactory("SapphirePool");
  const sapphirePool = await SapphirePool.deploy();
  await sapphirePool.deployed();

  const SapphireTrade = await ethers.getContractFactory("SapphireTrade");
  const sapphireTrade = await SapphireTrade.deploy();
  await sapphireTrade.deployed();

  console.log(`sapphireToken: "${sapphireToken.address}",`);
  console.log(`sapphirePool: "${sapphirePool.address}",`);
  console.log(`sapphireTrade: "${sapphireTrade.address}",`);
}

export default main;
