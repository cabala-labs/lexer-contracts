import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

import { _initialDeploymentFixture } from "../deploy.utils";
import { pairs, findPairIndex } from "../oracle/pairs.constants";

enum TradeType {
  LONG,
  SHORT,
}

describe("EmeraldTrade.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("open a long trade of long 200 usd value with 100 usdc", async function () {
      const { emeraldTrade, simplePriceFeed, usdc, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 100 usdc
      await usdc.mint(accounts[0].address, ethers.utils.parseUnits("100", 6));

      // approve lexer to spend usdc
      await usdc
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of EUR/USD
      const eurPrice = ethers.utils.parseEther("1.01");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("EUR/USD"),
        eurPrice,
        eurPrice
      );

      // open a trade of 200 EUR with 100 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("100", 6);
      const sizeAmount = ethers.utils.parseUnits("200", 6);
      await emeraldTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("EUR/USD"),
          TradeType.LONG,
          sizeAmount,
          usdc.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral
      expect(await usdc.balanceOf(emeraldTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // check the metadata of the nft
      const nftId = await emeraldTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const nftMetadata = await emeraldTrade.getPositionMetadata(nftId);
      expect(nftMetadata[0]).to.be.equal(4);
      expect(nftMetadata[1]).to.be.equal(0);
      expect(nftMetadata[2]).to.be.equal(eurPrice);
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount.mul(BigNumber.from(10).pow(12))
      );
      expect(nftMetadata[5]).to.be.equal(collateralAmount);
      expect(nftMetadata[6]).to.be.equal(0);
      expect(nftMetadata[7]).to.be.equal(0);
      expect(nftMetadata[8]).to.be.equal(0);
    });

    it("open a long trade of long 2000 usd value with 1 weth", async function () {
      const { emeraldTrade, simplePriceFeed, weth, usdc, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 1 weth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend weth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of EUR/USD
      const eurPrice = ethers.utils.parseEther("1.01");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("EUR/USD"),
        eurPrice,
        eurPrice
      );

      // set the price of ETH/USD
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        ethPrice,
        ethPrice
      );

      // open a trade of 2000 EUR with 1 weth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseUnits("2000", 6);
      await emeraldTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("EUR/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral, which is 1500 usdc
      expect(await usdc.balanceOf(emeraldTrade.address)).to.equal(
        ethers.utils.parseUnits("1500", 6)
      );

      // check if the balance of the nft is 1
      expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // check the metadata of the nft
      const nftId = await emeraldTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const nftMetadata = await emeraldTrade.getPositionMetadata(nftId);
      expect(nftMetadata.indexPair).to.be.equal(4);
      expect(nftMetadata.tradeType).to.be.equal(0);
      expect(nftMetadata.entryPrice).to.be.equal(eurPrice);
      expect(nftMetadata.size).to.be.equal(sizeAmount);
      expect(nftMetadata.totalCollateralBalance).to.be.equal(
        ethers.utils.parseUnits("1500", 18)
      );
      expect(nftMetadata.totalCollateralAmount).to.be.equal(
        ethers.utils.parseUnits("1500", 6)
      );
      expect(nftMetadata.exitPrice).to.be.equal(0);
      expect(nftMetadata.incurredFee).to.be.equal(0);
      expect(nftMetadata.lastBorrowRate).to.be.equal(0);
    });

    it("open a long trade of long 200 usd value with 100 usdc and then close it at profit", async function () {
      const { emeraldTrade, simplePriceFeed, usdc, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 100 usdc
      await usdc.mint(accounts[0].address, ethers.utils.parseUnits("100", 6));

      // approve lexer to spend usdc
      await usdc
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of EUR/USD
      const eurPrice = ethers.utils.parseEther("1.01");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("EUR/USD"),
        eurPrice,
        eurPrice
      );

      // open a trade of 200 EUR with 100 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("100", 6);
      const sizeAmount = ethers.utils.parseUnits("200", 6);
      await emeraldTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("EUR/USD"),
          TradeType.LONG,
          sizeAmount,
          usdc.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral
      expect(await usdc.balanceOf(emeraldTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // change the price of EUR/USD to 1.02
      const newEurPrice = ethers.utils.parseEther("1.02");

      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("EUR/USD"),
        newEurPrice,
        newEurPrice
      );

      // close the position
      await emeraldTrade
        .connect(accounts[0])
        .closePosition(0, usdc.address, accounts[0].address);

      // check if the position is closed
      expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(0);

      // check if the user has received the collateral
      const profit = ethers.utils.parseUnits("2", 6);
      expect(await usdc.balanceOf(accounts[0].address)).to.be.equal(
        collateralAmount.add(profit)
      );
    });

    it("open a long trade of long 200 usd value with 100 usdc and then close it at loss", async function () {
      const { emeraldTrade, simplePriceFeed, usdc, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 100 usdc
      await usdc.mint(accounts[0].address, ethers.utils.parseUnits("100", 6));

      // approve lexer to spend usdc
      await usdc
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of EUR/USD
      const eurPrice = ethers.utils.parseEther("1.01");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("EUR/USD"),
        eurPrice,
        eurPrice
      );

      // open a trade of 200 EUR with 100 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("100", 6);
      const sizeAmount = ethers.utils.parseUnits("200", 6);
      await emeraldTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("EUR/USD"),
          TradeType.LONG,
          sizeAmount,
          usdc.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral
      expect(await usdc.balanceOf(emeraldTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // change the price of EUR/USD to 1
      const newEurPrice = ethers.utils.parseEther("1");

      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("EUR/USD"),
        newEurPrice,
        newEurPrice
      );

      // close the position
      await emeraldTrade
        .connect(accounts[0])
        .closePosition(0, usdc.address, accounts[0].address);

      // check if the position is closed
      expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(0);

      // check if the user has received the collateral minus loss
      const loss = ethers.utils.parseUnits("2", 6);
      expect(await usdc.balanceOf(accounts[0].address)).to.be.equal(
        collateralAmount.sub(loss)
      );
    });
  });
  it("open a long trade of long 12 usd of pair EUR/USD value with 10 usdc at 0.9995 and then close at 0.9994", async function () {
    const { emeraldTrade, simplePriceFeed, usdc, atm, accounts } =
      await loadFixture(_initialDeploymentFixture);
    // get 100 usdc
    await usdc.mint(accounts[0].address, ethers.utils.parseUnits("100", 6));

    // approve lexer to spend usdc
    await usdc
      .connect(accounts[0])
      .approve(atm.address, ethers.constants.MaxUint256);

    // set the price of EUR/USD
    const eurPrice = ethers.utils.parseEther("0.9995");
    await simplePriceFeed.setPairLatestPrice(
      findPairIndex("EUR/USD"),
      eurPrice,
      eurPrice
    );

    // open a trade of 12 EUR with 10 usdc as collateral
    const collateralAmount = ethers.utils.parseUnits("10", 6);
    const sizeAmount = ethers.utils.parseUnits("12", 6);
    await emeraldTrade
      .connect(accounts[0])
      .createPosition(
        accounts[0].address,
        findPairIndex("EUR/USD"),
        TradeType.LONG,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

    // check if the position is opened
    // check if the contract has received the collateral
    expect(await usdc.balanceOf(emeraldTrade.address)).to.equal(
      collateralAmount
    );

    // check if the balance of the nft is 1
    expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(1);

    // change the price of EUR/USD to 0.9994
    const newEurPrice = ethers.utils.parseEther("0.9994");

    await simplePriceFeed.setPairLatestPrice(
      findPairIndex("EUR/USD"),
      newEurPrice,
      newEurPrice
    );

    // close the position
    await emeraldTrade
      .connect(accounts[0])
      .closePosition(0, usdc.address, accounts[0].address);

    // check if the position is closed
    expect(await emeraldTrade.balanceOf(accounts[0].address)).to.be.equal(0);

    // check if the user has received the collateral minus loss
    // const loss = ethers.utils.parseUnits("0.01", 6);
    // expect(await usdc.balanceOf(accounts[0].address)).
  });
});
