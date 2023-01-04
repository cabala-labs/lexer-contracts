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

enum OrderType {
  LIMIT,
  MARKET,
}

describe("EmeraldTrade.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it.only("open a long trade of long 200 usd value with 100 usdc", async function () {
      const {
        emeraldTrade,
        emeraldTradeOrder,
        simplePriceFeed,
        usdc,
        atm,
        accounts,
      } = await loadFixture(_initialDeploymentFixture);
      // get 100 usdc
      await usdc.mint(accounts[0].address, ethers.utils.parseUnits("100", 6));

      // approve lexer to spend usdc
      await usdc
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // open a trade order of 1000 usdc with 100 usdc and entry at EUR/USD 1.2
      const collateralAmount = ethers.utils.parseUnits("100", 6);
      const sizeAmount = ethers.utils.parseUnits("1000", 6);
      const entryPrice = ethers.utils.parseUnits("1.2", 18);

      await emeraldTradeOrder
        .connect(accounts[0])
        .createOrder(
          OrderType.LIMIT,
          entryPrice,
          findPairIndex("EUR/USD"),
          TradeType.LONG,
          sizeAmount,
          usdc.address,
          collateralAmount,
          collateralAmount
        );

      // check if a new order is created and its metadata
      expect(await emeraldTradeOrder.balanceOf(accounts[0].address)).to.equal(
        1
      );
      const orderId = await emeraldTradeOrder.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const orderMetadata = await emeraldTradeOrder.getOrderMetadata(orderId);
      expect(orderMetadata[0]).to.be.equal(OrderType.LIMIT);
      expect(orderMetadata[1]).to.be.equal(entryPrice);
      expect(orderMetadata[2]).to.be.equal(findPairIndex("EUR/USD"));
      expect(orderMetadata[3]).to.be.equal(TradeType.LONG);
      expect(orderMetadata[4]).to.be.equal(sizeAmount);
      expect(orderMetadata[5]).to.be.equal(usdc.address);
      expect(orderMetadata[6]).to.be.equal(collateralAmount);
      expect(orderMetadata[7]).to.be.equal(collateralAmount);

      // execute the order
      const feedingPairs = [findPairIndex("EUR/USD")];
      const feedingPrices = [entryPrice];
      const callbackAddress = emeraldTradeOrder.address;
      const executeABI = ["function executeOrder(uint256 _tokenId)"];
      const executeInterface = new ethers.utils.Interface(executeABI);
      const callbackSignature = executeInterface.encodeFunctionData(
        "executeOrder",
        [orderId]
      );

      await simplePriceFeed.setPairsLatestPricesWithCallback(
        feedingPairs,
        feedingPrices,
        callbackAddress,
        callbackSignature
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
      expect(nftMetadata[2]).to.be.equal(entryPrice);
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount.mul(BigNumber.from(10).pow(12))
      );
      expect(nftMetadata[5]).to.be.equal(collateralAmount);
      expect(nftMetadata[6]).to.be.equal(0);
      expect(nftMetadata[7]).to.be.equal(0);
      expect(nftMetadata[8]).to.be.equal(0);
    });
  });
});
