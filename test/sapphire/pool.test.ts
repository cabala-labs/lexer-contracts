import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

import { _initialDeploymentFixture } from "../deploy.utils";

describe("SapphirePool.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("stake 1 eth into the pool", async function () {
      const { sapphirePool, atm, weth, accounts } = await loadFixture(
        _initialDeploymentFixture
      );

      const ethAmount = ethers.utils.parseEther("1");

      // mint 1 eth to the user
      await weth.mint(accounts[0].address, ethAmount);

      // approve atm with 1 eth
      await weth.connect(accounts[0]).approve(atm.address, ethAmount);

      // stake 1 eth into the pool
      await sapphirePool
        .connect(accounts[0])
        .stake(accounts[0].address, weth.address, ethAmount, 0);
    });
    it("get the token price of the pool", async function () {
      const { sapphirePool } = await loadFixture(_initialDeploymentFixture);
      const poolTokenPrice = await sapphirePool.getPoolTokenPrice(0);

      // test if the price is 1e18
      expect(poolTokenPrice).to.equal(ethers.utils.parseEther("1"));
    });

    it("stake and test the token", async function () {
      const { sapphirePool, atm, usdc, owner } = await loadFixture(
        _initialDeploymentFixture
      );
      const poolTokenPrice = await sapphirePool.getPoolTokenPrice(0);

      // test if the price is 1e18
      expect(poolTokenPrice).to.equal(ethers.utils.parseEther("1"));

      // stake 10 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("10", 6));

      // allow atm to spend usdc
      await usdc.approve(atm.address, ethers.utils.parseUnits("10", 6));
      await sapphirePool.stake(
        owner.address,
        usdc.address,
        ethers.utils.parseUnits("10", 6),
        0
      );

      // get the token price
      const poolTokenPrice2 = await sapphirePool.getPoolTokenPrice(0);
      console.log(poolTokenPrice2.toString());
    });
  });
});
