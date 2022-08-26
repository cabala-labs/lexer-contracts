import { expect } from "chai";
import { ethers } from "hardhat";
import {
  Diamond,
  DiamondSwap,
  DiamondPool,
  MockToken,
  TokenPrice,
  AccessControl,
} from "../../typechain";

import {
  deployContract,
  deployMockToken,
  initializePool,
  swapToken,
  getMockToken,
  listTokenInOracle,
  setLatestPrice,
  toTokenDecimal,
  grantRight,
  approveToken,
} from "./test-lib";

describe("Trade for Diamond engine", function () {
  it("Open a 10x long position on WETH at price $1500 with $1000 WETH as collateral, then close at $1550", async function () {});
  it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1550", async function () {});
  it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1450", async function () {});
  it("Open a 10x long position on WETH at price $1500 with $100 USDC as collateral, then got liquidated at $1400", async function () {});
});
