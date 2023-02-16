import { ethers } from "hardhat";
import fsPromises from "fs/promises";

async function main() {
  const MockToken = await ethers.getContractFactory("MockToken");

  const weth = await MockToken.deploy("WETH", "WETH", 18);
  await weth.deployed();

  const usdc = await MockToken.deploy("USDC", "USDC", 6);
  await usdc.deployed();

  const wbtc = await MockToken.deploy("WBTC", "WBTC", 8);
  await wbtc.deployed();

  const BatchMint = await ethers.getContractFactory("BatchMint");
  const batchMint = await BatchMint.deploy(
    weth.address,
    usdc.address,
    wbtc.address
  );
  await batchMint.deployed();

  await weth.setAllowedAddress(batchMint.address, true);
  await usdc.setAllowedAddress(batchMint.address, true);
  await wbtc.setAllowedAddress(batchMint.address, true);

  //whitelist all contract address

  // const contracts = await fsPromises.readFile(
  //   __dirname + "/lexer-address.json",
  //   "utf8"
  // );
  // const contractAddresses = JSON.parse(contracts);

  // await usdc.setAllowedAddress(contractAddresses.atm, true);
  // await wbtc.setAllowedAddress(contractAddresses.atm, true);
  // await weth.setAllowedAddress(contractAddresses.atm, true);
  // await usdc.setAllowedAddress(contractAddresses.sapphireTrade, true);
  // await wbtc.setAllowedAddress(contractAddresses.sapphireTrade, true);
  // await weth.setAllowedAddress(contractAddresses.sapphireTrade, true);
  // await usdc.setAllowedAddress(contractAddresses.sapphireTradeOrder, true);
  // await wbtc.setAllowedAddress(contractAddresses.sapphireTradeOrder, true);
  // await weth.setAllowedAddress(contractAddresses.sapphireTradeOrder, true);
  // await usdc.setAllowedAddress(contractAddresses.sapphirePool, true);
  // await wbtc.setAllowedAddress(contractAddresses.sapphirePool, true);
  // await weth.setAllowedAddress(contractAddresses.sapphirePool, true);
  // await usdc.setAllowedAddress(contractAddresses.sapphireReward, true);
  // await wbtc.setAllowedAddress(contractAddresses.sapphireReward, true);
  // await weth.setAllowedAddress(contractAddresses.sapphireReward, true);
  // await usdc.setAllowedAddress(contractAddresses.emeraldTrade, true);
  // await wbtc.setAllowedAddress(contractAddresses.emeraldTrade, true);
  // await weth.setAllowedAddress(contractAddresses.emeraldTrade, true);
  // await usdc.setAllowedAddress(contractAddresses.emeraldTradeOrder, true);
  // await wbtc.setAllowedAddress(contractAddresses.emeraldTradeOrder, true);
  // await weth.setAllowedAddress(contractAddresses.emeraldTradeOrder, true);
  // await usdc.setAllowedAddress(contractAddresses.emeraldPool, true);
  // await wbtc.setAllowedAddress(contractAddresses.emeraldPool, true);
  // await weth.setAllowedAddress(contractAddresses.emeraldPool, true);
  // await usdc.setAllowedAddress(contractAddresses.emeraldReward, true);
  // await wbtc.setAllowedAddress(contractAddresses.emeraldReward, true);
  // await weth.setAllowedAddress(contractAddresses.emeraldReward, true);

  console.log("WETH deployed to:", weth.address);
  console.log("USDC deployed to:", usdc.address);
  console.log("WBTC deployed to:", wbtc.address);
  console.log("BatchMint deployed to:", batchMint.address);

  console.log(`
  ADDRESS_WETH=${weth.address}
  ADDRESS_USDC=${usdc.address}
  ADDRESS_WBTC=${wbtc.address}
  `);

  const tokenAddress = {
    WETH: weth.address,
    USDC: usdc.address,
    WBTC: wbtc.address,
  };

  console.log(JSON.stringify(tokenAddress, null, 2));
  await fsPromises.writeFile(
    __dirname + "/../token-address.json",
    JSON.stringify(tokenAddress, null, 2)
  );
}

main().then(console.log).catch(console.error);
