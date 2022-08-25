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
  stakeERC20,
} from "./test-lib";

describe.only("Earn for Diamond engine", function () {
  it("Stake 1000 USDC into empty vault", async function () {
    const [owner] = await ethers.getSigners();
    const { usdc, weth } = (await deployMockToken({ usdc: true, weth: true })) as {
      usdc: MockToken;
      weth: MockToken;
    };
    const { diamond, diamondPool, tokenPrice, accessControl } = (await deployContract()) as {
      diamond: Diamond;
      diamondPool: DiamondPool;
      tokenPrice: TokenPrice;
      accessControl: AccessControl;
    };
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Keeper"), owner);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Feeder"), owner);

    await listTokenInOracle(tokenPrice, weth);
    await listTokenInOracle(tokenPrice, usdc);

    await diamondPool.includeToken(usdc.address);

    await getMockToken(usdc, owner, await toTokenDecimal(usdc, 1500));
    await approveToken(owner, diamondPool.address, usdc);

    await setLatestPrice(tokenPrice, usdc, 1);

    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 1500));
    expect(await diamond.balanceOf(owner.address)).to.equal(0);

    await stakeERC20(owner, diamondPool, usdc, await toTokenDecimal(usdc, 1000));

    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 500));
    expect(await diamond.balanceOf(owner.address)).to.equal(await toTokenDecimal(diamond, 1000));
  });
});
