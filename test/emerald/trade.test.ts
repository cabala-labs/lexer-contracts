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
    it("open a long trade of 1 eth", async function () {
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
      const sizeAmount = ethers.utils.parseUnits("200", 18);
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
  });
});
