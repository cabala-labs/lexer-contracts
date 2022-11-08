import { ethers } from "hardhat";
import fsPromises from "fs/promises";
async function getMockTokens() {
  const tokens = await fsPromises.readFile(
    __dirname + "/token-address.json",
    "utf8"
  );

  const tokenAddresses = JSON.parse(tokens);

  const addressToMint = "0x03d666416b44B84cc61538B1aEF98A31Cb378AC5";

  const MockToken = await ethers.getContractFactory("MockToken");
  const usdc = MockToken.attach(tokenAddresses.USDC);
  const wbtc = MockToken.attach(tokenAddresses.WBTC);
  const weth = MockToken.attach(tokenAddresses.WETH);

  await usdc.mint(addressToMint, ethers.utils.parseUnits("100000000", 6));
  // await wbtc.mint(addressToMint, ethers.utils.parseUnits("1000", 8));
  // await weth.mint(addressToMint, ethers.utils.parseUnits("1000", 18));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
getMockTokens().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
