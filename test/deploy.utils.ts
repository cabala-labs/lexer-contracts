import { ethers } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { pairs, findPairIndex } from "./oracle/pairs.constants";

export async function deployAccess() {
  // deploy access control contract
  const AccessControl = await ethers.getContractFactory("AccessControl");
  const accessControl = await AccessControl.deploy();

  return accessControl;
}

export async function deployATM() {
  // deploy atm
  const ATM = await ethers.getContractFactory("ATM");
  const atm = await ATM.deploy();

  return atm;
}

export async function deployReferral() {
  // deploy referral
  const Referral = await ethers.getContractFactory("Referral");
  const referral = await Referral.deploy();

  return referral;
}

export async function deployOracle() {
  // deploy price feed
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.deploy();

  return simplePriceFeed;
}

export async function deployTokenLibs() {
  // deploy token library
  const TokenLibs = await ethers.getContractFactory("TokenLibs");
  const tokenLibs = await TokenLibs.deploy();

  return tokenLibs;
}

export async function deployPeripheralFixture() {
  const accessControl = await deployAccess();
  const atm = await deployATM();
  const referral = await deployReferral();
  const simplePriceFeed = await deployOracle();
  const tokenLibs = await deployTokenLibs();

  return { accessControl, atm, referral, simplePriceFeed, tokenLibs };
}

export async function deployMockTokens() {
  const MockToken = await ethers.getContractFactory("MockToken");
  const usdc = await MockToken.deploy("USDC", "USDC", 6);
  const wbtc = await MockToken.deploy("WBTC", "WBTC", 8);
  const weth = await MockToken.deploy("WETH", "WETH", 18);

  return { usdc, wbtc, weth };
}

export async function _initialDeploymentFixture() {
  const [owner, ...accounts] = await ethers.getSigners();

  // deploy mock tokens
  const MockToken = await ethers.getContractFactory("MockToken");
  const usdc = await MockToken.deploy("USDC", "USDC", 6);
  const wbtc = await MockToken.deploy("WBTC", "WBTC", 8);
  const weth = await MockToken.deploy("WETH", "WETH", 18);

  // deploy peripheral contracts
  const accessControl = await deployAccess();
  const atm = await deployATM();
  const referral = await deployReferral();
  const simplePriceFeed = await deployOracle();
  const tokenLibs = await deployTokenLibs();

  // deploy the sapphire contracts
  const SapphireToken = await ethers.getContractFactory("SapphireToken");
  const sapphireToken = await SapphireToken.deploy();

  const SapphirePool = await ethers.getContractFactory("SapphirePool", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const sapphirePool = await SapphirePool.deploy(
    simplePriceFeed.address,
    atm.address
  );
  const SapphireReward = await ethers.getContractFactory("SapphireReward");
  const sapphireReward = await SapphireReward.deploy(
    atm.address,
    referral.address
  );
  const SapphireTrade = await ethers.getContractFactory("SapphireTrade", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const sapphireTrade = await SapphireTrade.deploy(
    atm.address,
    simplePriceFeed.address
  );

  // deploy the emerald contracts
  const EmeraldToken = await ethers.getContractFactory("EmeraldToken");
  const emeraldToken = await EmeraldToken.deploy();

  const EmeraldPool = await ethers.getContractFactory("EmeraldPool", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const emeraldPool = await EmeraldPool.deploy(
    simplePriceFeed.address,
    atm.address
  );

  const EmeraldReward = await ethers.getContractFactory("EmeraldReward");
  const emeraldReward = await EmeraldReward.deploy(
    atm.address,
    referral.address
  );

  const EmeraldTrade = await ethers.getContractFactory("EmeraldTrade", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const emeraldTrade = await EmeraldTrade.deploy(
    atm.address,
    simplePriceFeed.address
  );

  // set up the peripheral contracts
  await atm.addFundManager(sapphirePool.address);
  await atm.addFundManager(sapphireReward.address);
  await atm.addFundManager(sapphireTrade.address);
  await atm.addFundManager(emeraldPool.address);
  await atm.addFundManager(emeraldReward.address);
  await atm.addFundManager(emeraldTrade.address);

  // add all pairs to price feed
  for (const pairId of Object.keys(pairs)) {
    await simplePriceFeed.addPair(pairId);
  }

  // map token addresses to pair ids
  simplePriceFeed.mapTokenToPair(usdc.address, findPairIndex("USDC/USD"));
  simplePriceFeed.mapTokenToPair(wbtc.address, findPairIndex("BTC/USD"));
  simplePriceFeed.mapTokenToPair(weth.address, findPairIndex("ETH/USD"));

  // feed initial prices
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
  await sapphirePool.setPoolToken(sapphireToken.address);
  await sapphirePool.setReward(sapphireReward.address);
  await sapphirePool.addToken(usdc.address, 0);
  await sapphirePool.addToken(wbtc.address, 0);
  await sapphirePool.addToken(weth.address, 0);

  await sapphireReward.setPoolToken(sapphireToken.address);
  await sapphireReward.setSwappablePool(sapphirePool.address);
  await sapphireReward.setFeeToken(usdc.address);

  await sapphireTrade.setPool(sapphirePool.address);
  await sapphireTrade.setSwap(sapphirePool.address);
  await sapphireTrade.setReward(sapphireReward.address);

  await sapphireTrade.addPair(2);
  await sapphireTrade.addPair(3);
  await sapphireTrade.setShortToken(usdc.address);
  await sapphireTrade.mapIndexPairToToken(2, weth.address);
  await sapphireTrade.mapIndexPairToToken(3, wbtc.address);

  // set up the emerald contracts
  await emeraldPool.setPoolToken(emeraldToken.address);
  await emeraldPool.setReward(emeraldReward.address);
  await emeraldPool.addToken(usdc.address, 0);

  await emeraldReward.setPoolToken(emeraldToken.address);
  await emeraldReward.setSwappablePool(sapphirePool.address);
  await emeraldReward.setFeeToken(usdc.address);

  await emeraldTrade.setPool(emeraldPool.address);
  await emeraldTrade.setSwap(sapphirePool.address);
  await emeraldTrade.setReward(emeraldReward.address);

  await emeraldTrade.addPair(4);
  await emeraldTrade.addPair(5);
  await emeraldTrade.setCollateralToken(usdc.address);

  // fund the pool with tokens
  await usdc.mint(
    sapphirePool.address,
    ethers.utils.parseUnits("100000000000", 6)
  );
  await wbtc.mint(sapphirePool.address, ethers.utils.parseUnits("1000000", 8));
  await weth.mint(sapphirePool.address, ethers.utils.parseUnits("1000000", 18));

  await usdc.mint(
    emeraldPool.address,
    ethers.utils.parseUnits("100000000000", 6)
  );

  return {
    owner,
    accounts,
    accessControl,
    atm,
    referral,
    simplePriceFeed,
    tokenLibs,
    sapphireToken,
    sapphirePool,
    sapphireReward,
    sapphireTrade,
    emeraldToken,
    emeraldPool,
    emeraldReward,
    emeraldTrade,
    usdc,
    wbtc,
    weth,
  };
}
