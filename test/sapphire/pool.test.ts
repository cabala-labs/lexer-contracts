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
  });
});
