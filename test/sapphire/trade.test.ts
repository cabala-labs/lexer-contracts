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
  });
});
