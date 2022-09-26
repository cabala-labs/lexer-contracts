import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SapphirePool.sol", function () {
  async function _initialDeploymentFixture() {
    const [owner, accounts] = await ethers.getSigners();

    // deploy sapphire token
    const SapphireToken = await ethers.getContractFactory("SapphireToken");
    const sapphireToken = await SapphireToken.deploy();
    // deploy price feed
    const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
    const simplePriceFeed = await SimplePriceFeed.deploy();
    // deploy sapphire pool
    const SapphirePool = await ethers.getContractFactory("SapphirePool");
    const sapphirePool = await SapphirePool.deploy(
      sapphireToken.address,
      simplePriceFeed.address
    );
    // deploy sapphire trade
    const SapphireTrade = await ethers.getContractFactory("SapphireTrade");
    const sapphireTrade = await SapphireTrade.deploy(sapphirePool.address);

    // deploy MockToken token as ETH, BTC and USDC
    const MockToken = await ethers.getContractFactory("MockToken");
    const eth = await MockToken.deploy("ETH", "ETH", 18);
    const btc = await MockToken.deploy("BTC", "BTC", 18);
    const usdc = await MockToken.deploy("USDC", "USDC", 6);

    return {
      owner,
      accounts,
      sapphireToken,
      sapphirePool,
      simplePriceFeed,
      eth,
      btc,
      usdc,
    };
  }

  describe("Deployment", function () {});
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {});
});
