import { ethers } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";

async function _initialDeploymentFixture() {
  const [owner, ...accounts] = await ethers.getSigners();

  // deploy token library
  const TokenLibs = await ethers.getContractFactory("TokenLibs");
  const tokenLibs = await TokenLibs.deploy();

  // deploy price feed
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.deploy();

  // deploy referral
  const Referral = await ethers.getContractFactory("Referral");
  const referral = await Referral.deploy();

  // deploy sapphire token
  const SapphireToken = await ethers.getContractFactory("SapphireToken");
  const sapphireToken = await SapphireToken.deploy();

  // deploy sapphire nft
  const SapphireNFT = await ethers.getContractFactory("SapphireNFT");
  const sapphireNFT = await SapphireNFT.deploy();

  // deploy sapphire pool
  const SapphirePool = await ethers.getContractFactory("SapphirePool", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const sapphirePool = await SapphirePool.deploy(simplePriceFeed.address);

  // deploy sapphire swap
  const SapphireSwap = await ethers.getContractFactory("SapphireSwap", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const sapphireSwap = await SapphireSwap.deploy(
    simplePriceFeed.address,
    sapphirePool.address
  );

  // deploy sapphire reward
  const SapphireReward = await ethers.getContractFactory("SapphireReward");
  const sapphireReward = await SapphireReward.deploy(
    sapphirePool.address,
    referral.address
  );

  // deploy sapphire trade
  const SapphireTrade = await ethers.getContractFactory("SapphireTrade", {
    libraries: {
      TokenLibs: tokenLibs.address,
    },
  });
  const sapphireTrade = await SapphireTrade.deploy(
    simplePriceFeed.address,
    sapphirePool.address
  );

  // set the contracts in pool
  await sapphirePool.setContracts(
    sapphireToken.address,
    sapphireNFT.address,
    sapphireSwap.address,
    sapphireTrade.address,
    sapphireReward.address
  );

  // refresh the contract addresses in each contract
  await sapphireTrade.setContract();
  await sapphireSwap.setContract();
  await sapphireReward.setContract();

  return {
    owner,
    accounts,
    sapphireToken,
    sapphirePool,
    sapphireSwap,
    sapphireReward,
    sapphireTrade,
    sapphireNFT,
    simplePriceFeed,
  };
}

async function _initialSettingsFixture() {
  const {
    owner,
    accounts,
    sapphireToken,
    sapphirePool,
    sapphireSwap,
    sapphireReward,
    sapphireTrade,
    sapphireNFT,
    simplePriceFeed,
  } = await loadFixture(_initialDeploymentFixture);

  // deploy MockToken token as ETH, BTC and USDC
  const MockToken = await ethers.getContractFactory("MockToken");
  const eth = await MockToken.deploy("ETH", "ETH", 18);
  const btc = await MockToken.deploy("BTC", "BTC", 8);
  const usdc = await MockToken.deploy("USDC", "USDC", 6);

  // add eth, btc and usdc to price feed
  await simplePriceFeed.addToken(eth.address);
  await simplePriceFeed.addToken(btc.address);
  await simplePriceFeed.addToken(usdc.address);

  // add eth, btc and usdc to sapphire pool
  await sapphirePool.addToken(eth.address);
  await sapphirePool.addToken(btc.address);
  await sapphirePool.addToken(usdc.address);

  // set initial price
  await simplePriceFeed.setLatestPrice(
    eth.address,
    ethers.utils.parseEther("1200"),
    ethers.utils.parseEther("1200")
  );
  await simplePriceFeed.setLatestPrice(
    btc.address,
    ethers.utils.parseEther("19000"),
    ethers.utils.parseEther("19000")
  );
  await simplePriceFeed.setLatestPrice(
    usdc.address,
    ethers.utils.parseEther("1"),
    ethers.utils.parseEther("1")
  );

  await sapphireReward.setFeeToken(usdc.address);
  await sapphireTrade.setShortToken(usdc.address);
  return {
    owner,
    accounts,
    sapphireToken,
    sapphirePool,
    sapphireSwap,
    sapphireReward,
    sapphireTrade,
    sapphireNFT,
    simplePriceFeed,
    eth,
    btc,
    usdc,
  };
}
export { _initialDeploymentFixture, _initialSettingsFixture };
