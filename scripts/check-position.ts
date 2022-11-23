import { ethers } from "hardhat";
import fsPromises from "fs/promises";
async function main() {
  const [owner] = await ethers.getSigners();

  const contracts = await fsPromises.readFile(
    __dirname + "/lexer-address.json",
    "utf8"
  );
  const contractAddresses = JSON.parse(contracts);

  const SapphireTrade = await ethers.getContractFactory("SapphireTrade", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });
  const EmeraldTrade = await ethers.getContractFactory("EmeraldTrade", {
    libraries: {
      TokenLibs: contractAddresses.tokenLibsAddress,
    },
  });
  const sapphireTrade = await SapphireTrade.attach(
    contractAddresses.sapphireTradeAddress
  );
  const emeraldTrade = await EmeraldTrade.attach(
    contractAddresses.emeraldTradeAddress
  );
  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = await SimplePriceFeed.attach(
    contractAddresses.simplePriceFeedAddress
  );

  // log the latest price feed
  // const latestPrice = await simplePriceFeed.getPairLatestPrice(1, 0);
  // console.log(latestPrice);
  // const latestPrice2 = await simplePriceFeed.getPairLatestPrice(1, 1);
  // console.log(latestPrice2);

  // get the position
  // const pos = await emeraldTrade.positions(11);
  // console.log(pos);
  // const pnl = await emeraldTrade.calPositionPnL(11, false);
  // console.log(pnl);

  const pos = await sapphireTrade.positions(34);
  console.log(pos);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
