import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

import { deployOracle, deployMockTokens } from "../deploy.utils";
import { pairs, findPairIndex } from "./pairs.constants";
enum Spread {
  HIGH,
  LOW,
}

describe("SimplePriceFeed.sol", function () {
  async function fixture() {
    const simplePriceFeed = await loadFixture(deployOracle);
    const { usdc, wbtc, weth } = await loadFixture(deployMockTokens);

    // add all pairs to price feed
    for (const pairId of Object.keys(pairs)) {
      await simplePriceFeed.addPair(pairId);
    }

    return { simplePriceFeed, usdc, wbtc, weth };
  }

  describe("Deployment", function () {
    it("initial deployment", async function () {
      await loadFixture(fixture);
    });
  });
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("set price for eth, btc and usdc", async function () {
      const { simplePriceFeed } = await loadFixture(fixture);
      const ethPrice = ethers.utils.parseEther("1500");
      const btcPrice = ethers.utils.parseEther("20000");
      const usdcPrice = ethers.utils.parseEther("1");

      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        ethPrice,
        ethPrice
      );
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("BTC/USD"),
        btcPrice,
        btcPrice
      );
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("USDC/USD"),
        usdcPrice,
        usdcPrice
      );

      expect(
        await simplePriceFeed.getPairLatestPrice(
          findPairIndex("ETH/USD"),
          Spread.HIGH
        )
      ).to.be.equal(ethPrice);
      expect(
        await simplePriceFeed.getPairLatestPrice(
          findPairIndex("BTC/USD"),
          Spread.HIGH
        )
      ).to.be.equal(btcPrice);
      expect(
        await simplePriceFeed.getPairLatestPrice(
          findPairIndex("USDC/USD"),
          Spread.HIGH
        )
      ).to.be.equal(usdcPrice);
    });

    it("set eth price 5 times", async function () {
      const { simplePriceFeed } = await loadFixture(fixture);
      const prices = [1500, 1700, 0.01, 55, 1234.4];
      for (const price of prices) {
        let ethPrice = ethers.utils.parseEther(price.toString());
        await simplePriceFeed.setPairLatestPrice(
          findPairIndex("ETH/USD"),
          ethPrice,
          ethPrice
        );
        expect(
          await simplePriceFeed.getPairLatestPrice(
            findPairIndex("ETH/USD"),
            Spread.HIGH
          )
        ).to.be.equal(ethPrice);
      }
    });
  });
});
