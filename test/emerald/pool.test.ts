import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

import { _initialDeploymentFixture } from "../deploy.utils";

describe("EmeraldPool.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("stake 100 USDC into the pool", async function () {
      const { emeraldPool, atm, usdc, accounts } = await loadFixture(
        _initialDeploymentFixture
      );

      const usdcAmount = ethers.utils.parseUnits("100", 6);

      // mint 100 usdc to the user
      await usdc.mint(accounts[0].address, usdcAmount);

      // approve atm with 100 usdc
      await usdc.connect(accounts[0]).approve(atm.address, usdcAmount);

      // stake 100 usdc into the pool
      await emeraldPool
        .connect(accounts[0])
        .stake(accounts[0].address, usdc.address, usdcAmount, 0);
    });
  });
});
