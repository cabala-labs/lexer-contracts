import { ethers } from "hardhat";

async function main() {
  const accounts = await ethers.getSigners();

  const tokenLibsAddress = "0x5B7eCd563617B50577B5abBd5eFbBd74307354A7";
  const sapphireTradeAddress = "0x7ca637FB59D2454f21C2Ea9ED976c0fab71b98c7";
  const sapphirePoolAddress = "0x4267EB2fe6Cf98195E2828E6685d659E7489150D";
  const usdcAddress = "0xF65Bcf87A424411DEC167f08C180eab977C9972C";
  const btcAddress = "0x54D3595517FC33Ca6fEb62B8037B633871C77421";

  const MockToken = await ethers.getContractFactory("MockToken");
  const usdc = await MockToken.attach(usdcAddress);
  const fillAmount = ethers.utils.parseUnits("10000000000000000000000000", 6);
  let tx = await usdc.mint(accounts[0].address, fillAmount);
  await tx.wait();

  const SapphirePool = await ethers.getContractFactory("SapphirePool", {
    libraries: {
      TokenLibs: tokenLibsAddress,
    },
  });
  const sapphirePool = await SapphirePool.attach(sapphirePoolAddress);

  tx = await sapphirePool.unstake(
    accounts[0].address,
    btcAddress,
    ethers.utils.parseUnits("600000", 18),
    0
  );
  await tx.wait();
  //   const SapphireTrade = await ethers.getContractFactory("SapphireTrade", {
  //     libraries: {
  //       TokenLibs: tokenLibsAddress,
  //     },
  //   });

  //   const sapphireTrade = await SapphireTrade.attach(
  //     sapphireTradeAddress
  //   ).connect(accounts[1]);

  //   const tx = await sapphireTrade.closePosition(
  //     146,
  //     "0xF65Bcf87A424411DEC167f08C180eab977C9972C"
  //   );
  //   await tx.wait();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
