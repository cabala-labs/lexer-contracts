import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

import { _initialDeploymentFixture } from "../deploy.utils";

describe("TokenLibs.sol", function () {
  it("normalizeDecimal for usdc", async function () {
    const { tokenLibs, usdc } = await loadFixture(_initialDeploymentFixture);
    const amount = ethers.utils.parseUnits("1", 6);
    const result = await tokenLibs.normalizeDecimal(amount, usdc.address);
    expect(result).to.equal(ethers.utils.parseUnits("1", 18));
  });

  it("normalizeDecimal for btc", async function () {
    const { tokenLibs, wbtc } = await loadFixture(_initialDeploymentFixture);
    const amount = ethers.utils.parseUnits("1", 8);
    const result = await tokenLibs.normalizeDecimal(amount, wbtc.address);
    expect(result).to.equal(ethers.utils.parseUnits("1", 18));
  });

  it("normalizeDecimal for eth", async function () {
    const { tokenLibs, weth } = await loadFixture(_initialDeploymentFixture);
    const amount = ethers.utils.parseUnits("1", 18);
    const result = await tokenLibs.normalizeDecimal(amount, weth.address);
    expect(result).to.equal(ethers.utils.parseUnits("1", 18));
  });
});
