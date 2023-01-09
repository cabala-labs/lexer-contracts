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

enum Instruction {
  LIMIT,
  MARKET,
}

describe.only("SapphireTrade.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("open a long trade of 1 eth", async function () {
      const {
        sapphireTrade,
        sapphireTradeOrder,
        simplePriceFeed,
        weth,
        atm,
        accounts,
      } = await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // open a trade order of 1 eth and entry at eth 1300
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      const entryPrice = ethers.utils.parseEther("1300");

      await sapphireTradeOrder
        .connect(accounts[0])
        .createOpenOrder(
          Instruction.LIMIT,
          entryPrice,
          findPairIndex("WETH/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount,
          collateralAmount
        );

      // check if a new order is created and its metadata
      expect(await sapphireTradeOrder.balanceOf(accounts[0].address)).to.equal(
        1
      );
      const orderId = await sapphireTradeOrder.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const orderMetadata = await sapphireTradeOrder.openOrders(orderId);
      expect(orderMetadata.instruction).to.be.equal(Instruction.LIMIT);
      expect(orderMetadata.orderPrice).to.be.equal(entryPrice);
      expect(orderMetadata.indexPair).to.be.equal(findPairIndex("WETH/USD"));
      expect(orderMetadata.tradeType).to.be.equal(TradeType.LONG);
      expect(orderMetadata.size).to.be.equal(sizeAmount);
      expect(orderMetadata.depositToken).to.be.equal(weth.address);
      expect(orderMetadata.depositAmount).to.be.equal(collateralAmount);
      expect(orderMetadata.totalDepositAmount).to.be.equal(collateralAmount);

      // execute the position
      const feedingPairs = [findPairIndex("WETH/USD")];
      const feedingPrices = [ethers.utils.parseEther("1300")];
      const callbackAddress = sapphireTradeOrder.address;
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
      expect(await weth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // check the metadata of the nft
      const nftId = await sapphireTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const nftMetadata = await sapphireTrade.getPositionMetadata(nftId);
      expect(nftMetadata[0]).to.be.equal(2);
      expect(nftMetadata[1]).to.be.equal(0);
      expect(nftMetadata[2]).to.be.equal(ethers.utils.parseEther("1300"));
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount
          .mul(ethers.utils.parseEther("1300"))
          .div(BigNumber.from(10).pow(18))
      );
      expect(nftMetadata[5]).to.be.equal(collateralAmount);
      expect(nftMetadata[6]).to.be.equal(0);
      expect(nftMetadata[7]).to.be.equal(0);
      expect(nftMetadata[8]).to.be.equal(0);
    });

    it("open a long trade of 1 eth in market order", async function () {
      const {
        sapphireTrade,
        sapphireTradeOrder,
        simplePriceFeed,
        weth,
        atm,
        accounts,
      } = await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // open a trade order of 1 eth and entry at market price
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      const entryPrice = ethers.utils.parseEther("0");

      await sapphireTradeOrder
        .connect(accounts[0])
        .createOpenOrder(
          Instruction.MARKET,
          entryPrice,
          findPairIndex("WETH/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount,
          collateralAmount
        );

      // check if a new order is created and its metadata
      expect(await sapphireTradeOrder.balanceOf(accounts[0].address)).to.equal(
        1
      );
      const orderId = await sapphireTradeOrder.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const orderMetadata = await sapphireTradeOrder.openOrders(orderId);
      expect(orderMetadata.instruction).to.be.equal(Instruction.MARKET);
      expect(orderMetadata.orderPrice).to.be.equal(entryPrice);
      expect(orderMetadata.indexPair).to.be.equal(findPairIndex("WETH/USD"));
      expect(orderMetadata.tradeType).to.be.equal(TradeType.LONG);
      expect(orderMetadata.size).to.be.equal(sizeAmount);
      expect(orderMetadata.depositToken).to.be.equal(weth.address);
      expect(orderMetadata.depositAmount).to.be.equal(collateralAmount);
      expect(orderMetadata.totalDepositAmount).to.be.equal(collateralAmount);

      // execute the position
      const feedingPairs = [findPairIndex("WETH/USD")];
      const feedingPrices = [ethers.utils.parseEther("1300")];
      const callbackAddress = sapphireTradeOrder.address;
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
      expect(await weth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // check the metadata of the nft
      const nftId = await sapphireTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const nftMetadata = await sapphireTrade.getPositionMetadata(nftId);
      expect(nftMetadata[0]).to.be.equal(2);
      expect(nftMetadata[1]).to.be.equal(0);
      expect(nftMetadata[2]).to.be.equal(ethers.utils.parseEther("1300"));
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount
          .mul(ethers.utils.parseEther("1300"))
          .div(BigNumber.from(10).pow(18))
      );
      expect(nftMetadata[5]).to.be.equal(collateralAmount);
      expect(nftMetadata[6]).to.be.equal(0);
      expect(nftMetadata[7]).to.be.equal(0);
      expect(nftMetadata[8]).to.be.equal(0);
    });

    it("open a long trade 1 eth in market order and close it", async function () {
      const {
        sapphireTrade,
        sapphireTradeOrder,
        simplePriceFeed,
        weth,
        atm,
        accounts,
      } = await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // open a trade order of 1 eth and entry at market price
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      const entryPrice = ethers.utils.parseEther("0");

      await sapphireTradeOrder
        .connect(accounts[0])
        .createOpenOrder(
          Instruction.MARKET,
          entryPrice,
          findPairIndex("WETH/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount,
          collateralAmount
        );

      // check if a new order is created and its metadata
      expect(await sapphireTradeOrder.balanceOf(accounts[0].address)).to.equal(
        1
      );
      const orderId = await sapphireTradeOrder.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const orderMetadata = await sapphireTradeOrder.openOrders(orderId);
      expect(orderMetadata.instruction).to.be.equal(Instruction.MARKET);
      expect(orderMetadata.orderPrice).to.be.equal(entryPrice);
      expect(orderMetadata.indexPair).to.be.equal(findPairIndex("WETH/USD"));
      expect(orderMetadata.tradeType).to.be.equal(TradeType.LONG);
      expect(orderMetadata.size).to.be.equal(sizeAmount);
      expect(orderMetadata.depositToken).to.be.equal(weth.address);
      expect(orderMetadata.depositAmount).to.be.equal(collateralAmount);
      expect(orderMetadata.totalDepositAmount).to.be.equal(collateralAmount);

      // execute the position
      const feedingPairs = [findPairIndex("WETH/USD")];
      const feedingPrices = [ethers.utils.parseEther("1300")];
      const callbackAddress = sapphireTradeOrder.address;
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
      expect(await weth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // check the metadata of the nft
      const nftId = await sapphireTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const nftMetadata = await sapphireTrade.getPositionMetadata(nftId);
      expect(nftMetadata[0]).to.be.equal(2);
      expect(nftMetadata[1]).to.be.equal(0);
      expect(nftMetadata[2]).to.be.equal(ethers.utils.parseEther("1300"));
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount
          .mul(ethers.utils.parseEther("1300"))
          .div(BigNumber.from(10).pow(18))
      );
      expect(nftMetadata[5]).to.be.equal(collateralAmount);
      expect(nftMetadata[6]).to.be.equal(0);
      expect(nftMetadata[7]).to.be.equal(0);
      expect(nftMetadata[8]).to.be.equal(0);

      // close the position
      // create a close order
      const closePrice = ethers.utils.parseEther("1400");
      await sapphireTradeOrder
        .connect(accounts[0])
        .createCloseOrder(
          Instruction.MARKET,
          nftId,
          closePrice,
          weth.address,
          accounts[0].address
        );

      // check if a new order is created and its metadata
      expect(await sapphireTradeOrder.balanceOf(accounts[0].address)).to.equal(
        1
      );
      const closeOrderId = await sapphireTradeOrder.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );
      const closeOrderMetadata = await sapphireTradeOrder.closeOrders(
        closeOrderId
      );

      expect(closeOrderMetadata.instruction).to.be.equal(Instruction.MARKET);
      expect(closeOrderMetadata.orderPrice).to.be.equal(closePrice);
      expect(closeOrderMetadata.positionId).to.be.equal(nftId);
      expect(closeOrderMetadata.withdrawToken).to.be.equal(weth.address);
      expect(closeOrderMetadata.withdrawAddress).to.be.equal(
        accounts[0].address
      );

      // execute the close order
      const closeCallbackAddress = sapphireTradeOrder.address;
      const closeCallbackSignature = executeInterface.encodeFunctionData(
        "executeOrder",
        [closeOrderId]
      );

      await simplePriceFeed.setPairsLatestPricesWithCallback(
        feedingPairs,
        feedingPrices,
        closeCallbackAddress,
        closeCallbackSignature
      );

      // check if the position is closed
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(0);
    });
  });
});
