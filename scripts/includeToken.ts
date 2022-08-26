import { ethers } from "hardhat";

async function includeToken() {
  const DiamondPool = await ethers.getContractFactory("DiamondPool", {
    libraries: {
      TokenLibs: "0x3ce4C0cEd7dbbe3177A594a1d933466d1fCAa0A0",
    },
  });
  const diamondPool = await DiamondPool.attach(process.env.DIAMOND_POOL_ADDRESS as string);

  await diamondPool.includeToken(process.env.WETH_ADDRESS as string);
}

includeToken()
  .then()
  .catch((error) => {
    console.error(error);
  });
