import { ethers } from "hardhat";

async function deployMockToken() {
  const TokenPrice = await ethers.getContractFactory("TokenPrice");
  const tokenPrice = await TokenPrice.attach("0xb33F680d8EdCAbb7A50812B819B45496604F2409");

  const EUROC = await ethers.getContractFactory("EUROC");
  const euroc = await EUROC.deploy();
  await euroc.deployed();
  console.log("EUROC deployed to:", euroc.address);
  // tokenPrice.addToken(euroc.address);

  const USDC = await ethers.getContractFactory("USDC");
  const usdc = await USDC.deploy();
  await usdc.deployed();
  console.log("USDC deployed to:", usdc.address);
  // tokenPrice.addToken(usdc.address);

  const WETH = await ethers.getContractFactory("WETH");
  const wETH = await WETH.deploy();
  await wETH.deployed();
  console.log("WETH deployed to:", wETH.address);

  // tokenPrice.addToken(wETH.address);
}

deployMockToken()
  .then()
  .catch((error) => {
    console.error(error);
  });
