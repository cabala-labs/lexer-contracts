import { ethers } from "hardhat";

async function deploySapphire(
  accessControlAddress: string,
  atmAddress: string,
  simplePriceFeedAddress: string,
  referralAddress: string,
  tokenLibAddress: string
) {
  console.log("deploying sapphire token");
  const SapphireToken = await ethers.getContractFactory("SapphireToken");
  const sapphireToken = await SapphireToken.deploy();

  console.log("deploying sapphire pool");
  const SapphirePool = await ethers.getContractFactory("SapphirePool", {
    libraries: {
      TokenLibs: tokenLibAddress,
    },
  });
  const sapphirePool = await SapphirePool.deploy(
    simplePriceFeedAddress,
    atmAddress
  );
  console.log("deploying sapphire reward");
  const SapphireReward = await ethers.getContractFactory("SapphireReward");
  const sapphireReward = await SapphireReward.deploy(
    atmAddress,
    referralAddress
  );
  console.log("deploying sapphire trade");
  const SapphireTrade = await ethers.getContractFactory("SapphireTrade", {
    libraries: {
      TokenLibs: tokenLibAddress,
    },
  });
  const sapphireTrade = await SapphireTrade.deploy(
    atmAddress,
    simplePriceFeedAddress
  );

  console.log("deploying sapphire trade order");
  const SapphireTradeOrder = await ethers.getContractFactory(
    "SapphireTradeOrder"
  );
  const sapphireTradeOrder = await SapphireTradeOrder.deploy(
    atmAddress,
    simplePriceFeedAddress
  );

  console.log(`sapphireToken: "${sapphireToken.address}",`);
  console.log(`sapphirePool: "${sapphirePool.address}",`);
  console.log(`sapphireTrade: "${sapphireTrade.address}",`);
  console.log(`sapphireReward: "${sapphireReward.address}",`);
  console.log(`sapphireTradeOrder: "${sapphireTradeOrder.address}",`);

  console.log(`
  sapphireToken=${sapphireToken.address}
  sapphirePool=${sapphirePool.address}
  sapphireTrade=${sapphireTrade.address}
  sapphireReward=${sapphireReward.address}
  sapphireTradeOrder=${sapphireTradeOrder.address}
  `);

  return {
    sapphireTokenAddress: sapphireToken.address,
    sapphirePoolAddress: sapphirePool.address,
    sapphireTradeAddress: sapphireTrade.address,
    sapphireRewardAddress: sapphireReward.address,
    sapphireTradeOrderAddress: sapphireTradeOrder.address,
  };
}

export default deploySapphire;
