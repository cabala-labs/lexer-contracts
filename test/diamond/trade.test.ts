import { expect } from "chai";
import { ethers } from "hardhat";
import { wrapEthersProvider } from "hardhat-tracer";
import {
  Diamond,
  DiamondPool,
  DiamondTrade,
  MockToken,
  TokenPrice,
  AccessControl,
} from "../../typechain";

import {
  createPosition,
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

describe.only("Trade for Diamond engine", function () {
  it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1550", async function () {
    const [owner] = await ethers.getSigners();
    const { usdc, weth } = (await deployMockToken({ usdc: true, weth: true })) as {
      usdc: MockToken;
      weth: MockToken;
    };
    const { diamondTrade, diamondPool, tokenPrice, accessControl } = (await deployContract({
      trade: true,
    })) as {
      diamondTrade: DiamondTrade;
      diamondPool: DiamondPool;
      tokenPrice: TokenPrice;
      accessControl: AccessControl;
    };

    await initializePool(diamondPool, usdc);
    await initializePool(diamondPool, weth);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Keeper"), owner);
    await grantRight(accessControl, ethers.utils.formatBytes32String("TokenPrice_Feeder"), owner);

    await listTokenInOracle(tokenPrice, weth);
    await listTokenInOracle(tokenPrice, usdc);

    await getMockToken(usdc, owner, await toTokenDecimal(usdc, 2500));
    await approveToken(owner, diamondTrade.address, usdc);

    await setLatestPrice(tokenPrice, weth, 1500);
    await setLatestPrice(tokenPrice, usdc, 1);

    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 2500));

    await createPosition(
      diamondTrade,
      usdc,
      await toTokenDecimal(usdc, 1000),
      weth,
      await toTokenDecimal(weth, 2),
      0
    );
    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 1500));
    const position = await diamondTrade._openPositions(owner.address, 0);
    await setLatestPrice(tokenPrice, weth, 1550);

    const profit = await diamondTrade.getPositionPnL(position);

    console.log(profit);

    await diamondTrade.closePosition(0, weth.address);
    expect(await weth.balanceOf(owner.address)).to.equal(await ethers.utils.parseUnits("0.71", 18));
  });
  // it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1550", async function () {});
  // it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1450", async function () {});
  // it("Open a 10x long position on WETH at price $1500 with $100 USDC as collateral, then got liquidated at $1400", async function () {});
});
