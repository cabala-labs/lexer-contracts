import { ethers } from "hardhat";

async function main() {
  console.log("setting up emeraldTradeOrder");
  const EmeraldTradeOrder = await ethers.getContractFactory(
    "EmeraldTradeOrder"
  );
  const emeraldTradeOrder = await EmeraldTradeOrder.attach(
    "0x9423B5286A0214EDAf89c3B2ea070665DcF50C18"
  );
  console.log(await emeraldTradeOrder.contractName());
  try {
    await emeraldTradeOrder.setTrade(
      "0x2114F018a676E0aa685b03c1ee21781e0dab93Db"
    );
  } catch (e) {
    console.log(e);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
