import { ethers } from "hardhat";
import fsPromises from "fs/promises";

const pairs = {
  1: "USDC/USD",
  2: "ETH/USD",
  3: "BTC/USD",
  4: "EUR/USD",
  5: "GBP/JPY",
};

const findPairIndex = (pair: string) => {
  const index = Object.values(pairs).findIndex((p) => p === pair);
  return index + 1;
};

async function main() {
  const tokens = await fsPromises.readFile(
    __dirname + "/token-address.json",
    "utf8"
  );
  const tokenAddresses = JSON.parse(tokens);

  const contracts = await fsPromises.readFile(
    __dirname + "/lexer-address.json",
    "utf8"
  );
  const contractAddresses = JSON.parse(contracts);

  // set up the peripheral contracts
  console.log("setting up atm");
  const ATM = await ethers.getContractFactory("ATM");
  const atm = await ATM.attach(contractAddresses.atmAddress);
  await atm.addFundManager(contractAddresses.sapphirePoolAddress);
  await atm.addFundManager(contractAddresses.sapphireRewardAddress);
  await atm.addFundManager(contractAddresses.sapphireTradeAddress);
  await atm.addFundManager(contractAddresses.emeraldPoolAddress);
  await atm.addFundManager(contractAddresses.emeraldRewardAddress);
  await atm.addFundManager(contractAddresses.emeraldTradeAddress);

  console.log("setting up SimplePriceFeed");
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.attach(
    contractAddresses.simplePriceFeedAddress
  );
  // add all pairs to price feed
  for (const pairId of Object.keys(pairs)) {
    await simplePriceFeed.addPair(pairId);
  }

  // map token addresses to pair ids
  await simplePriceFeed.mapTokenToPair(
    tokenAddresses.USDC,
    findPairIndex("USDC/USD")
  );
  await simplePriceFeed.mapTokenToPair(
    tokenAddresses.WBTC,
    findPairIndex("BTC/USD")
  );
  await simplePriceFeed.mapTokenToPair(
    tokenAddresses.WETH,
    findPairIndex("ETH/USD")
  );

  // feed initial prices
  console.log("feed initial prices");
  const oneUSD = ethers.utils.parseEther("1");
  await simplePriceFeed.setPairLatestPrice(
    findPairIndex("USDC/USD"),
    oneUSD,
    oneUSD
  );
  await simplePriceFeed.setPairLatestPrice(
    findPairIndex("BTC/USD"),
    oneUSD,
    oneUSD
  );
  await simplePriceFeed.setPairLatestPrice(
    findPairIndex("ETH/USD"),
    oneUSD,
    oneUSD
  );

  // set up the sapphire contracts
  console.log("setting up sapphirePool");
  const SapphirePool = await ethers.getContractFactory("SapphirePool", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });
  const sapphirePool = await SapphirePool.attach(
    contractAddresses.sapphirePoolAddress
  );

  await sapphirePool.setPoolToken(contractAddresses.sapphireTokenAddress);
  await sapphirePool.setReward(contractAddresses.sapphireRewardAddress);
  await sapphirePool.addToken(tokenAddresses.USDC, 0);
  await sapphirePool.addToken(tokenAddresses.WBTC, 0);
  await sapphirePool.addToken(tokenAddresses.WETH, 0);

  console.log("setting up sapphireReward");
  const SapphireReward = await ethers.getContractFactory("SapphireReward");
  const sapphireReward = await SapphireReward.attach(
    contractAddresses.sapphireRewardAddress
  );
  await sapphireReward.setPoolToken(contractAddresses.sapphireTokenAddress);
  await sapphireReward.setSwappablePool(sapphirePool.address);
  await sapphireReward.setFeeToken(tokenAddresses.USDC);

  console.log("setting up sapphireTrade");
  const SapphireTrade = await ethers.getContractFactory("SapphireTrade", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });
  const sapphireTrade = await SapphireTrade.attach(
    contractAddresses.sapphireTradeAddress
  );
  await sapphireTrade.setPool(sapphirePool.address);
  await sapphireTrade.setSwap(sapphirePool.address);
  await sapphireTrade.setReward(sapphireReward.address);

  await sapphireTrade.addPair(2);
  await sapphireTrade.addPair(3);
  await sapphireTrade.setShortToken(tokenAddresses.USDC);
  await sapphireTrade.setPairCollateral(2, tokenAddresses.WETH);
  await sapphireTrade.setPairCollateral(3, tokenAddresses.WBTC);

  // set up the emerald contracts
  console.log("setting up emeraldPool");
  const EmeraldPool = await ethers.getContractFactory("EmeraldPool", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });
  const emeraldPool = await EmeraldPool.attach(
    contractAddresses.emeraldPoolAddress
  );

  await emeraldPool.setPoolToken(contractAddresses.emeraldTokenAddress);
  await emeraldPool.setReward(contractAddresses.emeraldRewardAddress);
  await emeraldPool.addToken(tokenAddresses.USDC, 0);

  console.log("setting up emeraldReward");
  const EmeraldReward = await ethers.getContractFactory("EmeraldReward");
  const emeraldReward = await EmeraldReward.attach(
    contractAddresses.emeraldRewardAddress
  );
  await emeraldReward.setPoolToken(contractAddresses.emeraldTokenAddress);
  await emeraldReward.setSwappablePool(sapphirePool.address);
  await emeraldReward.setFeeToken(tokenAddresses.USDC);

  console.log("setting up emeraldTrade");
  const EmeraldTrade = await ethers.getContractFactory("EmeraldTrade", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });

  const emeraldTrade = await EmeraldTrade.attach(
    contractAddresses.emeraldTradeAddress
  );
  await emeraldTrade.setPool(emeraldPool.address);
  await emeraldTrade.setSwap(sapphirePool.address);
  await emeraldTrade.setReward(emeraldReward.address);

  await emeraldTrade.addPair(4);
  await emeraldTrade.addPair(5);
  await emeraldTrade.setCollateralToken(tokenAddresses.USDC);
}

main().then(console.log).catch(console.error);
