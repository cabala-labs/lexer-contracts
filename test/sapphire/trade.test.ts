import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

import { _initialDeploymentFixture, _initialSettingsFixture } from "./utils";

describe("SapphireTrade.sol", function () {
  describe("Role", function () {});
  describe("Revert", function () {});
  describe("Events", function () {});
  describe("Functions", function () {
    it("open a trade of 1 eth", async function () {
      const { sapphireTrade, simplePriceFeed, sapphireNFT, eth, owner } =
        await loadFixture(_initialSettingsFixture);
      // get 1 eth
      await eth.mint(owner.address, ethers.utils.parseEther("1"));
      // approve sapphireTrade to spend eth
      await eth.approve(sapphireTrade.address, ethers.constants.MaxUint256);

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // open a trade of 10 eth with 1 eth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      await sapphireTrade.createPosition(
        owner.address,
        eth.address,
        0,
        sizeAmount,
        eth.address,
        collateralAmount
      );

      // check if the position is opened
      // check if the contract has received the collateral
      expect(await eth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );
      // check if the balance of the nft is 1
      expect(await sapphireNFT.balanceOf(owner.address)).to.be.equal(1);
      // check the metadata of the nft
      const nftId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      const nftMetadata = await sapphireNFT.getPositionMetadata(nftId);
      expect(nftMetadata[0]).to.be.equal(eth.address);
      expect(nftMetadata[1]).to.be.equal(0);
      expect(nftMetadata[2]).to.be.equal(ethPrice);
      expect(nftMetadata[3]).to.be.equal(sizeAmount);
      expect(nftMetadata[4]).to.be.equal(
        collateralAmount.mul(ethPrice).div(BigNumber.from(10).pow(18))
      );
      expect(nftMetadata[5]).to.be.equal(0);
      expect(nftMetadata[6]).to.be.equal(0);
    });

    it("close a trade of 1 eth", async function () {
      const { sapphireTrade, simplePriceFeed, sapphireNFT, eth, owner } =
        await loadFixture(_initialSettingsFixture);
      // get 1 eth
      await eth.mint(owner.address, ethers.utils.parseEther("1"));
      // approve sapphireTrade to spend eth
      await eth.approve(sapphireTrade.address, ethers.constants.MaxUint256);

      // set the price of eth
      const ethPrice = ethers.utils.parseEther("1500");
      await simplePriceFeed.setLatestPrice(eth.address, ethPrice, ethPrice);

      // open a trade of 10 eth with 1 eth as collateral
      const collateralAmount = ethers.utils.parseEther("1");
      const sizeAmount = ethers.utils.parseEther("10");
      await sapphireTrade.createPosition(
        owner.address,
        eth.address,
        0,
        sizeAmount,
        eth.address,
        collateralAmount
      );

      // check the eth balance of the trading contract
      expect(await eth.balanceOf(sapphireTrade.address)).to.equal(
        collateralAmount
      );

      // check if the position is opened
      // check if the balance of the nft is 1
      expect(await sapphireNFT.balanceOf(owner.address)).to.be.equal(1);
      // close the trade
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);

      await sapphireTrade.closePosition(tokenId, eth.address);
      // check if the position NFT is burned
      expect(await sapphireNFT.balanceOf(owner.address)).to.be.equal(0);
      expect(await sapphireNFT.ownerOf(tokenId)).to.be.equal(
        ethers.constants.AddressZero
      );

      // check the balance of the user
      expect(await eth.balanceOf(owner.address)).to.be.equal(collateralAmount);
    });

    it("open a trade of long 10 btc with 1.5 btc at 20000, close at 21000", async function () {
      const {
        sapphireTrade,
        simplePriceFeed,
        sapphireNFT,
        sapphirePool,
        btc,
        owner,
        accounts,
      } = await loadFixture(_initialSettingsFixture);

      // stake 50 btc into the pool
      await btc
        .connect(accounts[0])
        .mint(accounts[0].address, ethers.utils.parseUnits("50", 8));
      await btc
        .connect(accounts[0])
        .approve(sapphirePool.address, ethers.constants.MaxUint256);
      await sapphirePool
        .connect(accounts[0])
        .stake(
          accounts[0].address,
          btc.address,
          ethers.utils.parseUnits("50", 8),
          0
        );

      // get 1 btc
      await btc.mint(owner.address, ethers.utils.parseEther("1.5"));
      // approve sapphireTrade to spend btc
      await btc.approve(sapphireTrade.address, ethers.constants.MaxUint256);

      // set the price of btc
      const btcPrice = ethers.utils.parseEther("20000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice, btcPrice);

      // open a trade of 10 btc with 1.5 btc as collateral
      const collateralAmount = ethers.utils.parseEther("1.5");
      const sizeAmount = ethers.utils.parseEther("10");
      await sapphireTrade.createPosition(
        owner.address,
        btc.address,
        0,
        sizeAmount,
        btc.address,
        collateralAmount
      );

      // set the price of btc
      const btcPrice2 = ethers.utils.parseEther("21000");
      await simplePriceFeed.setLatestPrice(btc.address, btcPrice2, btcPrice2);

      const pnl = sizeAmount
        .mul(btcPrice2.sub(btcPrice))
        .div(BigNumber.from(10).pow(18));

      // close the position
      const tokenId = await sapphireNFT.tokenOfOwnerByIndex(owner.address, 0);
      await sapphireTrade.closePosition(tokenId, btc.address);

      // check the btc balance of the user
      expect(await btc.balanceOf(owner.address)).to.be.equal(
        collateralAmount.add(pnl).div(BigNumber.from(10).pow(10))
      );
    });
  });
});
