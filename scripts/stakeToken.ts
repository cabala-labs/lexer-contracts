import { ethers } from "hardhat";
import fsPromises from "fs/promises";

async function stakeToken() {
  const [owner] = await ethers.getSigners();
  const contracts = await fsPromises.readFile(
    __dirname + "/lexer-address.json",
    "utf8"
  );
  const contractAddresses = JSON.parse(contracts);

  const tokens = await fsPromises.readFile(
    __dirname + "/token-address.json",
    "utf8"
  );

  const tokenAddresses = JSON.parse(tokens);
  const bearAddress = "0x7D5878883e6B030A3C6e437A86C8fC3a067EEDa2";
  // const addressToMint = "0x7D5878883e6B030A3C6e437A86C8fC3a067EEDa2";

  const MockToken = await ethers.getContractFactory("MockToken");
  const usdc = MockToken.attach(tokenAddresses.USDC);

  const sapphirePool = await ethers.getContractFactory("SapphirePool", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });
  const sapphirePoolContract = sapphirePool.attach(
    contractAddresses.sapphirePoolAddress
  );

  await usdc.mint(owner.address, ethers.utils.parseUnits("10", 6));

  // allow atm to spend usdc
  await usdc.approve(
    contractAddresses.atmAddress,
    ethers.utils.parseUnits("10", 6)
  );
  await sapphirePoolContract.stake(
    owner.address,
    usdc.address,
    ethers.utils.parseUnits("10", 6),
    0
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
stakeToken().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
