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

describe("Swap for Diamond engine", function () {
  it("Swap 100 USDC for WETH at price WETH $1500", async function () {
    const [owner] = await ethers.getSigners();
    const { usdc, weth } = (await deployMockToken({ usdc: true, weth: true })) as {
      usdc: MockToken;
      weth: MockToken;
    };
    const { diamondPool, diamondSwap, tokenPrice, accessControl } = (await deployContract({
      swap: true,
    })) as {
      diamondPool: DiamondPool;
      diamondSwap: DiamondSwap;
      tokenPrice: TokenPrice;
      accessControl: AccessControl;
    };
    await initializePool(diamondPool, usdc);
    await initializePool(diamondPool, weth);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Keeper"), owner);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Feeder"), owner);

    await listTokenInOracle(tokenPrice, weth);
    await listTokenInOracle(tokenPrice, usdc);

    await getMockToken(usdc, owner, await toTokenDecimal(usdc, 1500));
    await approveToken(owner, diamondSwap.address, usdc);

    await setLatestPrice(tokenPrice, weth, 1500);
    await setLatestPrice(tokenPrice, usdc, 1);

    expect(await weth.balanceOf(owner.address)).to.equal(0);
    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 1500));

    await swapToken(
      diamondSwap,
      usdc,
      await toTokenDecimal(usdc, 1500),
      weth,
      await toTokenDecimal(weth, 1)
    );

    expect(await weth.balanceOf(owner.address)).to.equal(await toTokenDecimal(weth, 1));
    expect(await usdc.balanceOf(owner.address)).to.equal(0);
  });

  it("Swap 1 WETH for 1500 USDC at price WETH $1500", async function () {
    const [owner] = await ethers.getSigners();
    const { usdc, weth } = (await deployMockToken({ usdc: true, weth: true })) as {
      usdc: MockToken;
      weth: MockToken;
    };
    const { diamondPool, diamondSwap, tokenPrice, accessControl } = (await deployContract({
      swap: true,
    })) as {
      diamondPool: DiamondPool;
      diamondSwap: DiamondSwap;
      tokenPrice: TokenPrice;
      accessControl: AccessControl;
    };
    await initializePool(diamondPool, usdc);
    await initializePool(diamondPool, weth);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Keeper"), owner);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Feeder"), owner);

    await listTokenInOracle(tokenPrice, weth);
    await listTokenInOracle(tokenPrice, usdc);

    await getMockToken(weth, owner, await toTokenDecimal(weth, 1));
    await approveToken(owner, diamondSwap.address, weth);

    await setLatestPrice(tokenPrice, weth, 1500);
    await setLatestPrice(tokenPrice, usdc, 1);

    expect(await usdc.balanceOf(owner.address)).to.equal(0);
    expect(await weth.balanceOf(owner.address)).to.equal(await toTokenDecimal(weth, 1));

    await swapToken(
      diamondSwap,
      weth,
      await toTokenDecimal(weth, 1),
      usdc,
      await toTokenDecimal(usdc, 1500)
    );

    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 1500));
    expect(await weth.balanceOf(owner.address)).to.equal(0);
  });
});
