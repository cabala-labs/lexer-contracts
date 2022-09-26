import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("SimplePriceFeed.sol", function () {
  async function _initialDeploymentFixture() {
    const [owner, accounts] = await ethers.getSigners();
    const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
    const simplePriceFeed = await SimplePriceFeed.deploy();

    // deploy MockToken token as ETH, BTC and USDC
    const MockToken = await ethers.getContractFactory("MockToken");
    const eth = await MockToken.deploy("ETH", "ETH", 18);
    const btc = await MockToken.deploy("BTC", "BTC", 18);
    const usdc = await MockToken.deploy("USDC", "USDC", 6);

    return { owner, accounts, simplePriceFeed, eth, btc, usdc };
  }

  async function _initialSettingsFixture() {
    const { owner, accounts, simplePriceFeed, eth, btc, usdc } =
      await loadFixture(_initialDeploymentFixture);

    // add eth, btc and usdc to price feed
    await simplePriceFeed.addToken(eth.address);
    await simplePriceFeed.addToken(btc.address);
    await simplePriceFeed.addToken(usdc.address);

    return { owner, accounts, simplePriceFeed, eth, btc, usdc };
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
    it("set price for eth, btc and usdc", async function () {
      const { simplePriceFeed, eth, btc, usdc } = await loadFixture(
        _initialSettingsFixture
      );
      const ethPrice = ethers.utils.parseEther("1500");
      const btcPrice = ethers.utils.parseEther("20000");
      const usdcPrice = ethers.utils.parseUnits("1", 6);
      await simplePriceFeed.setLatestPrice(eth.address, [ethPrice, ethPrice]);

      expect(
        (await simplePriceFeed.getLatestPrice(eth.address)).price
      ).deep.equal([ethPrice, ethPrice]);

      await simplePriceFeed.setLatestPrice(btc.address, [btcPrice, btcPrice]);
      expect(
        (await simplePriceFeed.getLatestPrice(btc.address)).price
      ).deep.equal([btcPrice, btcPrice]);

      await simplePriceFeed.setLatestPrice(usdc.address, [
        usdcPrice,
        usdcPrice,
      ]);

      expect(
        (await simplePriceFeed.getLatestPrice(usdc.address)).price
      ).deep.equal([usdcPrice, usdcPrice]);
    });

    it("set eth price 5 times", async function () {
      const { simplePriceFeed, eth } = await loadFixture(
        _initialSettingsFixture
      );
      const prices = [1500, 1700, 0.01, 55, 1234.4];
      for (const price of prices) {
        let ethPrice = ethers.utils.parseEther(price.toString());
        await simplePriceFeed.setLatestPrice(eth.address, [ethPrice, ethPrice]);
        expect(
          (await simplePriceFeed.getLatestPrice(eth.address)).price
        ).deep.equal([ethPrice, ethPrice]);
      }
    });
  });
});
