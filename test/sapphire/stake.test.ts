import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

import { _initialDeploymentFixture, _initialSettingsFixture } from "./utils";

describe("SapphirePool.sol | staking", function () {
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
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // stake 1 eth into the pool
      const ethAmount = ethers.utils.parseEther("1");

      await sapphirePool.stake(
        owner.address,
        eth.address,
        ethAmount,
        ethers.utils.parseEther("1500")
      );

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
