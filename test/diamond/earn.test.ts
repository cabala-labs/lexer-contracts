import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  Diamond,
  DiamondSwap,
  DiamondPool,
  MockToken,
  TokenPrice,
  AccessControl,
  // eslint-disable-next-line node/no-missing-import
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

describe("Earn for Diamond engine", function () {
  it("Stake 1000 USDC into empty vault", async function () {
    const [owner] = await ethers.getSigners();
    const { usdc } = (await deployMockToken({ usdc: true, weth: true })) as {
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

  it("Stake 1.5 WETH into empty vault at price $1200", async function () {
    const [owner] = await ethers.getSigners();
    const { weth } = (await deployMockToken({ usdc: true, weth: true })) as {
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

    await diamondPool.includeToken(weth.address);

    await getMockToken(weth, owner, await toTokenDecimal(weth, 2));
    await approveToken(owner, diamondPool.address, weth);

    await setLatestPrice(tokenPrice, weth, 1200);

    expect(await weth.balanceOf(owner.address)).to.equal(await toTokenDecimal(weth, 2));
    expect(await diamond.balanceOf(owner.address)).to.equal(0);

    await stakeERC20(owner, diamondPool, weth, ethers.utils.parseUnits("1.5", 18));

    expect(await weth.balanceOf(owner.address)).to.equal(ethers.utils.parseUnits("0.5", 18));
    expect(await diamond.balanceOf(owner.address)).to.equal(await toTokenDecimal(diamond, 1800));
  });

  it("Stake 1.5 WETH into vault with $500 USDC at price $1200", async function () {
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

    await diamondPool.includeToken(weth.address);
    await diamondPool.includeToken(usdc.address);

    await setLatestPrice(tokenPrice, weth, 1200);
    await setLatestPrice(tokenPrice, usdc, 1);

    // owner stake $500 USDC into the vault
    await getMockToken(usdc, owner, await toTokenDecimal(usdc, 500));
    await approveToken(owner, diamondPool.address, usdc);
    await stakeERC20(owner, diamondPool, usdc, await toTokenDecimal(usdc, 500));
    expect(await usdc.balanceOf(owner.address)).to.equal(0);
    expect(await diamond.balanceOf(owner.address)).to.equal(await toTokenDecimal(diamond, 500));

    // owner stake $1.5 WETH into the vault
    await getMockToken(weth, owner, await toTokenDecimal(weth, 2));
    await approveToken(owner, diamondPool.address, weth);
    await stakeERC20(owner, diamondPool, weth, ethers.utils.parseUnits("1.5", 18));
    expect(await weth.balanceOf(owner.address)).to.equal(ethers.utils.parseUnits("0.5", 18));
    expect(await diamond.balanceOf(owner.address)).to.equal(await toTokenDecimal(diamond, 2300));
  });

  it("Stake $500 USDC into the vault with $1200 worth of WETH and $1300 worth of diamond minted", async function () {
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

    await diamondPool.includeToken(weth.address);
    await diamondPool.includeToken(usdc.address);

    await setLatestPrice(tokenPrice, weth, 1300);
    await setLatestPrice(tokenPrice, usdc, 1);

    // owner stake 1 WETH into the vault
    await getMockToken(weth, owner, await toTokenDecimal(weth, 1));
    await approveToken(owner, diamondPool.address, weth);
    await stakeERC20(owner, diamondPool, weth, await toTokenDecimal(weth, 1));
    // return;
    expect(await weth.balanceOf(owner.address)).to.equal(0);
    expect(await diamond.balanceOf(owner.address)).to.equal(await toTokenDecimal(diamond, 1300));
    expect(await diamond.totalSupply()).to.equal(await toTokenDecimal(diamond, 1300));

    // WETH price dropped from $1300 to $1200
    await setLatestPrice(tokenPrice, weth, 1200);

    // check if the pool has $1200 worth of asset
    expect(await diamondPool.getPoolTotalBalance()).to.equal(await toTokenDecimal(weth, 1200));

    // owner stake $500 USDC into the vault
    await getMockToken(usdc, owner, await toTokenDecimal(usdc, 500));
    await approveToken(owner, diamondPool.address, usdc);
    await stakeERC20(owner, diamondPool, usdc, await toTokenDecimal(usdc, 500));
    expect(await usdc.balanceOf(owner.address)).to.equal(0);
    let supposedAmount = ethers.utils.parseEther("500");
    supposedAmount = supposedAmount
      .mul(BigNumber.from(10).pow(18))
      .div(await diamondPool.getDiamondPrice());
    supposedAmount = supposedAmount.add(ethers.utils.parseEther("1300"));
    expect(await diamond.balanceOf(owner.address)).to.equal(supposedAmount);
  });
});
