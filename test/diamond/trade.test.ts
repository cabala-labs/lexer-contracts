import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";
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

    // log the initial values for the position
    const collateralBalance = await toTokenDecimal(usdc, 1000);
    const positionSize = await toTokenDecimal(weth, 2);

    await createPosition(diamondTrade, usdc, collateralBalance, weth, positionSize, 0);

    expect(await usdc.balanceOf(owner.address)).to.equal(await toTokenDecimal(usdc, 1500));
    const position = await diamondTrade._openPositions(owner.address, 0);
    await setLatestPrice(tokenPrice, weth, 1550);

    // find the closing balance
    const [profit, loss] = await diamondTrade.getPositionPnL(position);
    console.log("pnl:" + profit + " " + loss);
    console.log("collateral:" + collateralBalance);
    let closingBalance = collateralBalance.mul(BigNumber.from(10).pow(12)).add(profit).sub(loss);
    console.log("test:" + closingBalance);
    const exitWETHPrice = (await tokenPrice.getPrice(weth.address))[0].mul(
      BigNumber.from(10).pow(10)
    );
    closingBalance = closingBalance.mul(BigNumber.from(10).pow(18)).div(exitWETHPrice);

    // close the trade
    await diamondTrade.closePosition(0, weth.address);

    expect(await weth.balanceOf(owner.address)).to.equal(closingBalance);
  });
  // it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1550", async function () {});
  // it("Open a 10x long position on WETH at price $1500 with $1000 USDC as collateral, then close at $1450", async function () {});
  // it("Open a 10x long position on WETH at price $1500 with $100 USDC as collateral, then got liquidated at $1400", async function () {});
});
