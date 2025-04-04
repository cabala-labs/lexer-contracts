import { ethers } from "hardhat";
import fsPromises from "fs/promises";

const pairs = {
  1: "USDC/USD",
  2: "WETH/USD",
  3: "WBTC/USD",
  4: "EUR/USD",
  5: "JPY/USD",
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
  await atm.addFundManager(contractAddresses.sapphireTradeOrderAddress);
  await atm.addFundManager(contractAddresses.emeraldPoolAddress);
  await atm.addFundManager(contractAddresses.emeraldRewardAddress);
  await atm.addFundManager(contractAddresses.emeraldTradeAddress);
  await atm.addFundManager(contractAddresses.emeraldTradeOrderAddress);

  console.log("setting up SimplePriceFeed");
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.attach(
    contractAddresses.simplePriceFeedAddress
  );
  // add all pairs to price feed
  await simplePriceFeed.addPair(1);
  await simplePriceFeed.addPair(2);
  await simplePriceFeed.addPair(3);
  await simplePriceFeed.addPair(4);
  await simplePriceFeed.addPair(5);

  // map token addresses to pair ids
  await simplePriceFeed.mapTokenToPair(
    tokenAddresses.USDC,
    findPairIndex("USDC/USD")
  );
  await simplePriceFeed.mapTokenToPair(
    tokenAddresses.WBTC,
    findPairIndex("WBTC/USD")
  );
  await simplePriceFeed.mapTokenToPair(
    tokenAddresses.WETH,
    findPairIndex("WETH/USD")
  );

  // feed initial prices
  console.log("feed initial prices");
  const oneUSD = ethers.utils.parseEther("1");
  await simplePriceFeed.setPairLatestPrice(findPairIndex("USDC/USD"), oneUSD);
  await simplePriceFeed.setPairLatestPrice(findPairIndex("WBTC/USD"), oneUSD);
  await simplePriceFeed.setPairLatestPrice(findPairIndex("WETH/USD"), oneUSD);
  await simplePriceFeed.setPairLatestPrice(findPairIndex("EUR/USD"), oneUSD);
  await simplePriceFeed.setPairLatestPrice(findPairIndex("JPY/USD"), oneUSD);

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
  await sapphireTrade.mapIndexPairToToken(2, tokenAddresses.WETH);
  await sapphireTrade.mapIndexPairToToken(3, tokenAddresses.WBTC);

  console.log("setting up sapphireTradeOrder");
  const SapphireTradeOrder = await ethers.getContractFactory(
    "SapphireTradeOrder"
  );
  const sapphireTradeOrder = await SapphireTradeOrder.attach(
    contractAddresses.sapphireTradeOrderAddress
  );

  await sapphireTradeOrder.setTrade(sapphireTrade.address);

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

  console.log("setting up emeraldTradeOrder");
  const EmeraldTradeOrder = await ethers.getContractFactory(
    "EmeraldTradeOrder"
  );
  const emeraldTradeOrder = await EmeraldTradeOrder.attach(
    contractAddresses.emeraldTradeOrderAddress
  );
  await emeraldTradeOrder.setTrade(emeraldTrade.address);

  // fill the pools with token
  console.log("filling pools with token");
  const MockToken = await ethers.getContractFactory("MockToken");
  const usdc = await MockToken.attach(tokenAddresses.USDC);
  const wbtc = await MockToken.attach(tokenAddresses.WBTC);
  const weth = await MockToken.attach(tokenAddresses.WETH);

  await usdc.mint(emeraldPool.address, ethers.utils.parseUnits("1000000", 6));
  await usdc.mint(sapphirePool.address, ethers.utils.parseUnits("1000000", 6));
  await wbtc.mint(sapphirePool.address, ethers.utils.parseUnits("100000", 8));
  await weth.mint(sapphirePool.address, ethers.utils.parseEther("100000"));
}

main().then(console.log).catch(console.error);
