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

describe.skip("SapphireTrade.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("open a long trade of 1 eth", async function () {
      const { sapphireTrade, simplePriceFeed, weth, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        ethPrice,
        ethPrice
      );

      // open a trade of 10 eth with 1 eth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      await sapphireTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("ETH/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount
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
      expect(nftMetadata[2]).to.be.equal(ethPrice);
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount.mul(ethPrice).div(BigNumber.from(10).pow(18))
      );
      expect(nftMetadata[5]).to.be.equal(collateralAmount);
      expect(nftMetadata[6]).to.be.equal(0);
      expect(nftMetadata[7]).to.be.equal(0);
      expect(nftMetadata[8]).to.be.equal(0);
    });

    it("close a long trade of 1 eth", async function () {
      const { sapphireTrade, simplePriceFeed, weth, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        ethPrice,
        ethPrice
      );

      // open a trade of 10 eth with 1 eth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      await sapphireTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("ETH/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral
      expect(await weth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // get the number of trades of the user
      const userActiveTradeCount = await sapphireTrade.balanceOf(
        accounts[0].address
      );

      // get the first trade
      const tokenId = await sapphireTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );

      // close the trade
      await sapphireTrade
        .connect(accounts[0])
        .closePosition(tokenId, weth.address, accounts[0].address);
    });

    it("open a long trade of 1 eth and get liquidated", async function () {
      const { sapphireTrade, simplePriceFeed, weth, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        ethPrice,
        ethPrice
      );

      // open a trade of 10 eth with 1 eth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      await sapphireTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("ETH/USD"),
          TradeType.LONG,
          sizeAmount,
          weth.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral
      expect(await weth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );

      // check if the balance of the nft is 1
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // change eth price to 1400
      const newEthPrice = ethers.utils.parseEther("1400");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        newEthPrice,
        newEthPrice
      );

      // try to liquidate the position and expect error of position_not_liquidatable
      await expect(
        sapphireTrade.connect(accounts[0]).liquidatePosition(0)
      ).to.be.revertedWith("position_not_liquidatable");

      // change eth price to 1350
      const newEthPrice2 = ethers.utils.parseEther("1350");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        newEthPrice2,
        newEthPrice2
      );

      // liquidate the position
      await sapphireTrade.liquidatePosition(0);

      // check if the position is closed
      // check if the user has received the collateral
      expect(await weth.balanceOf(accounts[0].address)).to.equal(0);
    });

    it("open a short trade of 2 eth with 1 eth at price $1491.1, close at $1489.5", async function () {
      const { sapphireTrade, simplePriceFeed, weth, usdc, atm, accounts } =
        await loadFixture(_initialDeploymentFixture);
      // get 1 eth
      await weth.mint(accounts[0].address, ethers.utils.parseEther("1"));

      // approve lexer to spend eth
      await weth
        .connect(accounts[0])
        .approve(atm.address, ethers.constants.MaxUint256);

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1491.1");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        ethPrice,
        ethPrice
      );

      // open a trade of 2 eth with 1 eth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("2");
      await sapphireTrade
        .connect(accounts[0])
        .createPosition(
          accounts[0].address,
          findPairIndex("ETH/USD"),
          TradeType.SHORT,
          sizeAmount,
          weth.address,
          collateralAmount
        );

      // check if the position is opened
      // check if the contract has received the collateral
      // expect(await usdc.balanceOf(sapphireTrade.address)).to.equal(
      //   collateralAmount.mul()
      // );

      // check if the balance of the nft is 1
      expect(await sapphireTrade.balanceOf(accounts[0].address)).to.be.equal(1);

      // get the number of trades of the user
      const userActiveTradeCount = await sapphireTrade.balanceOf(
        accounts[0].address
      );

      // get the first trade
      const tokenId = await sapphireTrade.tokenOfOwnerByIndex(
        accounts[0].address,
        0
      );

      // change eth price to 1489.5
      const newEthPrice = ethers.utils.parseEther("1489.5");
      await simplePriceFeed.setPairLatestPrice(
        findPairIndex("ETH/USD"),
        newEthPrice,
        newEthPrice
      );

      // close the trade
      await sapphireTrade
        .connect(accounts[0])
        .closePosition(tokenId, weth.address, accounts[0].address);

      expect(await weth.balanceOf(accounts[0].address)).to.be.equal(
        ethers.utils.parseEther("1.003222557905337361")
      );
    });

    it.skip("open a long trade of 2 eth with 1200 usdc at price $1200, close at $1150", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        eth,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);
      // get 1200 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("1200", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // get 2 eth
      await eth.mint(owner.address, ethers.utils.parseEther("2"));
      // stake 2 eth into the pool
      await eth.approve(atm.address, ethers.constants.MaxUint256);
      await sapphirePool.stake(
        owner.address,
        eth.address,
        ethers.utils.parseEther("2"),
        0
      );

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1200");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // open a trade of 2 eth with 1200 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("1200", 6);
      const sizeAmount = ethers.utils.parseEther("2");
      await sapphireTrade.createPosition(
        owner.address,
        eth.address,
        0,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of eth
      const ethPrice2 = ethers.utils.parseEther("1150");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice2, ethPrice2);

      const pnl = sizeAmount
        .mul(ethPrice2.sub(ethPrice))
        .div(BigNumber.from(10).pow(18));

      // close the position
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, eth.address, owner.address);

      // check the eth balance of the user
      expect(await eth.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseEther("0.913043478260869566")
      );
    });

    it.skip("open a long trade of 2 eth with 1200 usdc at price $1200, close at $1250", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        eth,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);
      // get 1200 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("1200", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // get 2 eth
      await eth.mint(owner.address, ethers.utils.parseEther("2"));
      // stake 2 eth into the pool
      await eth.approve(atm.address, ethers.constants.MaxUint256);
      await sapphirePool.stake(
        owner.address,
        eth.address,
        ethers.utils.parseEther("2"),
        0
      );

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1200");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // open a trade of 2 eth with 1200 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("1200", 6);
      const sizeAmount = ethers.utils.parseEther("2");
      await sapphireTrade.createPosition(
        owner.address,
        eth.address,
        0,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of eth
      const ethPrice2 = ethers.utils.parseEther("1150");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice2, ethPrice2);

      const pnl = sizeAmount
        .mul(ethPrice2.sub(ethPrice))
        .div(BigNumber.from(10).pow(18));

      // close the position
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, eth.address, owner.address);

      // check the eth balance of the user
      expect(await eth.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseEther("0.913043478260869566")
      );
    });

    it.skip("open a short trade of 2 eth with 1200 usdc at price $1200, close at $1250", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        eth,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);

      // get 1200 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("1200", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // get 2400 usdc
      await eth.mint(owner.address, ethers.utils.parseEther("2"));
      // stake 2400 usdc into the pool
      await eth.approve(atm.address, ethers.constants.MaxUint256);

      await sapphirePool.stake(
        owner.address,
        eth.address,
        ethers.utils.parseUnits("2400", 6),
        0
      );

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1200");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // open a short trade of 2 eth with 1200 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("1200", 6);
      const sizeAmount = ethers.utils.parseEther("2");

      await sapphireTrade.createPosition(
        owner.address,
        eth.address,
        1,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of eth
      const ethPrice2 = ethers.utils.parseEther("1250");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice2, ethPrice2);

      const pnl = sizeAmount
        .mul(ethPrice.sub(ethPrice2))
        .div(BigNumber.from(10).pow(18));

      // close the position
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, usdc.address, owner.address);

      // check the eth balance of the user
      expect(await usdc.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseUnits("1100", 6)
      );
    });

    it.skip("open a short trade of 2 eth with 1200 usdc at price $1200, close at $1150", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        eth,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);

      // get 1200 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("1200", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // get 2400 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("2400", 6));
      // stake 2400 usdc into the pool
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      await sapphirePool.stake(
        owner.address,
        usdc.address,
        ethers.utils.parseUnits("2400", 6),
        0
      );

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1200");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // open a short trade of 2 eth with 1200 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("1200", 6);
      const sizeAmount = ethers.utils.parseEther("2");

      await sapphireTrade.createPosition(
        owner.address,
        eth.address,
        1,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of eth
      const ethPrice2 = ethers.utils.parseEther("1150");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice2, ethPrice2);

      const pnl = sizeAmount
        .mul(ethPrice.sub(ethPrice2))
        .div(BigNumber.from(10).pow(18));

      // close the position
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, usdc.address, owner.address);

      // check the eth balance of the user
      expect(await usdc.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseUnits("1300", 6)
      );
    });

    it.skip("open a short trade for 2 btc with 10000 usdc at price $20000, close at $19000", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        btc,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);

      // get 10000 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("10000", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // get 2000 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("2000", 6));
      // stake 2000 usdc into the pool
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      await sapphirePool.stake(
        owner.address,
        usdc.address,
        ethers.utils.parseUnits("2000", 6),
        0
      );

      // set the price of btc
      const btcPrice = ethers.utils.parseEther("20000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice, btcPrice);

      // open a short trade of 2 btc with 10000 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("10000", 6);
      const sizeAmount = ethers.utils.parseUnits("2", 8);

      await sapphireTrade.createPosition(
        owner.address,
        btc.address,
        1,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of btc
      const btcPrice2 = ethers.utils.parseEther("19000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice2, btcPrice2);

      const pnl = sizeAmount
        .mul(btcPrice.sub(btcPrice2))
        .div(BigNumber.from(10).pow(18));

      // close the position
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, usdc.address, owner.address);

      // check the eth balance of the user
      expect(await usdc.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseUnits("12000", 6)
      );
    });

    it.skip("open a short trade for 2 btc with 10000 usdc at price $20000, close at $21000", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        btc,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);

      // get 10000 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("10000", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // set the price of btc
      const btcPrice = ethers.utils.parseEther("20000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice, btcPrice);

      // open a short trade of 2 btc with 10000 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("10000", 6);
      const sizeAmount = ethers.utils.parseUnits("2", 8);

      await sapphireTrade.createPosition(
        owner.address,
        btc.address,
        1,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of btc
      const btcPrice2 = ethers.utils.parseEther("21000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice2, btcPrice2);

      // close the position
      console.log(await usdc.balanceOf(sapphireTrade.address));

      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, usdc.address, owner.address);
      console.log(await usdc.balanceOf(sapphireTrade.address));

      // check the eth balance of the user
      expect(await usdc.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseUnits("8000", 6)
      );
    });

    it.skip("open a short trade for 2 btc with 10000 usdc at price $20000, close at $20001", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        btc,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);

      // get 10000 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("10000", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // set the price of btc
      const btcPrice = ethers.utils.parseEther("20000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice, btcPrice);

      // open a short trade of 2 btc with 10000 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("10000", 6);
      const sizeAmount = ethers.utils.parseUnits("2", 8);

      await sapphireTrade.createPosition(
        owner.address,
        btc.address,
        1,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of btc
      const btcPrice2 = ethers.utils.parseEther("20001");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice2, btcPrice2);

      // close the position
      console.log(await usdc.balanceOf(sapphireTrade.address));

      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, usdc.address, owner.address);
      console.log(await usdc.balanceOf(sapphireTrade.address));

      // check the eth balance of the user
      expect(await usdc.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseUnits("9998", 6)
      );
    });

    it.skip("open a short trade for 2 btc with 10000 usdc at price $20000, close at $19999", async function () {
      const {
        sapphireTrade,
        sapphirePool,
        simplePriceFeed,
        sapphireNFT,
        btc,
        usdc,
        owner,
        atm,
      } = await loadFixture(_initialSettingsFixture);

      // get 10000 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("10000", 6));
      // approve sapphireTrade to spend usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // get 2 usdc
      await usdc.mint(owner.address, ethers.utils.parseUnits("2", 6));
      // approve sapphirePool to stake usdc
      await usdc.approve(atm.address, ethers.constants.MaxUint256);

      // stake 2 usdc
      await sapphirePool.stake(
        owner.address,
        usdc.address,
        ethers.utils.parseUnits("2", 6),
        0
      );

      // set the price of btc
      const btcPrice = ethers.utils.parseEther("20000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice, btcPrice);

      // open a short trade of 2 btc with 10000 usdc as collateral
      const collateralAmount = ethers.utils.parseUnits("10000", 6);
      const sizeAmount = ethers.utils.parseUnits("2", 8);

      await sapphireTrade.createPosition(
        owner.address,
        btc.address,
        1,
        sizeAmount,
        usdc.address,
        collateralAmount
      );

      // set the price of btc
      const btcPrice2 = ethers.utils.parseEther("19999");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice2, btcPrice2);

      // close the position
      console.log(await usdc.balanceOf(sapphireTrade.address));

      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, usdc.address, owner.address);
      console.log(await usdc.balanceOf(sapphireTrade.address));

      // check the eth balance of the user
      expect(await usdc.balanceOf(owner.address)).to.be.equal(
        ethers.utils.parseUnits("10002", 6)
      );
    });
  });
});
