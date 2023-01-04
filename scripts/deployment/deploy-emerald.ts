import { ethers } from "hardhat";

async function deployEmerald(
  accessControlAddress: string,
  atmAddress: string,
  simplePriceFeedAddress: string,
  referralAddress: string,
  tokenLibAddress: string
) {
  console.log("deploying emerald token");
  const EmeraldToken = await ethers.getContractFactory("EmeraldToken");
  const emeraldToken = await EmeraldToken.deploy();

  console.log("deploying emerald pool");
  const EmeraldPool = await ethers.getContractFactory("EmeraldPool", {
    libraries: {
      TokenLibs: tokenLibAddress,
    },
  });
  const emeraldPool = await EmeraldPool.deploy(
    simplePriceFeedAddress,
    atmAddress
  );
  console.log("deploying emerald reward");
  const EmeraldReward = await ethers.getContractFactory("EmeraldReward");
  const emeraldReward = await EmeraldReward.deploy(atmAddress, referralAddress);
  console.log("deploying emerald trade");
  const EmeraldTrade = await ethers.getContractFactory("EmeraldTrade", {
    libraries: {
      TokenLibs: tokenLibAddress,
    },
  });
  const emeraldTrade = await EmeraldTrade.deploy(
    atmAddress,
    simplePriceFeedAddress
  );

  console.log("deploying emerald trade order");
  const EmeraldTradeOrder = await ethers.getContractFactory(
    "EmeraldTradeOrder"
  );
  const emeraldTradeOrder = await EmeraldTradeOrder.deploy(
    atmAddress,
    simplePriceFeedAddress
  );

  console.log(`emeraldToken: "${emeraldToken.address}",`);
  console.log(`emeraldPool: "${emeraldPool.address}",`);
  console.log(`emeraldTrade: "${emeraldTrade.address}",`);
  console.log(`emeraldReward: "${emeraldReward.address}",`);
  console.log(`emeraldTradeOrder: "${emeraldTradeOrder.address}",`);

  console.log(`
  emeraldToken=${emeraldToken.address}
  emeraldPool=${emeraldPool.address}
  emeraldTrade=${emeraldTrade.address}
  emeraldReward=${emeraldReward.address}
  emeraldTradeOrder=${emeraldTradeOrder.address}
  `);

  return {
    emeraldTokenAddress: emeraldToken.address,
    emeraldPoolAddress: emeraldPool.address,
    emeraldTradeAddress: emeraldTrade.address,
    emeraldRewardAddress: emeraldReward.address,
    emeraldTradeOrderAddress: emeraldTradeOrder.address,
  };
}

export default deployEmerald;
