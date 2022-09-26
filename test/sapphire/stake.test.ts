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

    return {
      owner,
      accounts,
      sapphireToken,
      sapphirePool,
      simplePriceFeed,
    };
  }

  async function _initialSettingsFixture() {
    const { owner, accounts, sapphirePool, sapphireToken, simplePriceFeed } =
      await loadFixture(_initialDeploymentFixture);

    // deploy MockToken token as ETH, BTC and USDC
    const MockToken = await ethers.getContractFactory("MockToken");
    const eth = await MockToken.deploy("ETH", "ETH", 18);
    const btc = await MockToken.deploy("BTC", "BTC", 18);
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
    await simplePriceFeed.setLatestPrice(eth.address, [0, 0]);
    await simplePriceFeed.setLatestPrice(btc.address, [0, 0]);
    await simplePriceFeed.setLatestPrice(usdc.address, [0, 0]);

    return {
      owner,
      accounts,
      sapphirePool,
      sapphireToken,
      simplePriceFeed,
      eth,
      btc,
      usdc,
    };
  }

  describe("Deployment", function () {
    it("initial deployment", async function () {
      await loadFixture(_initialDeploymentFixture);
    });
  });
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("stake 1 eth into the pool", async function () {
      const { sapphireToken, sapphirePool, eth, owner, simplePriceFeed } =
        await loadFixture(_initialSettingsFixture);
      // get 1 mock eth and approve the pool
      await eth.mint(owner.address, ethers.utils.parseEther("1"));
      await eth.approve(sapphirePool.address, ethers.constants.MaxUint256);

      // set the price of eth to 1500
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setLatestPrice(eth.address, [ethPrice, ethPrice]);

      // stake 1 eth into the pool
      const ethAmount = ethers.utils.parseEther("1");

      await sapphirePool.stake(owner.address, eth.address, ethAmount);

      // check if the pool has 1 eth
      expect(await eth.balanceOf(sapphirePool.address)).to.equal(ethAmount);
      // check if the pool has 1500 USD value
      expect(await sapphirePool.getPoolAssetBalance(1)).to.equal(ethPrice);
      // check if the user has 1500 pool tokens
      expect(await sapphireToken.balanceOf(owner.address)).to.equal(
        ethers.utils.parseEther("1500")
      );
    });
  });
});
