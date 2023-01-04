import { ethers } from "hardhat";
import fsPromises from "fs/promises";
import { BigNumber } from "ethers";
enum TradeType {
  LONG,
  SHORT,
}

enum OrderType {
  LIMIT,
  MARKET,
}

async function main() {
  const [owner] = await ethers.getSigners();

  const contracts = await fsPromises.readFile(
    __dirname + "/lexer-address.json",
    "utf8"
  );
  const contractAddresses = JSON.parse(contracts);

  const tokens = await fsPromises.readFile(
    __dirname + "/token-address.json",
    "utf8"
  );
  const tokenAddresses = JSON.parse(tokens);

  const SimplePriceFeed = await ethers.getContractFactory("SimplePriceFeed");
  const simplePriceFeed = SimplePriceFeed.attach(
    contractAddresses.simplePriceFeedAddress
  );

  // get 1 weth
  const MockToken = await ethers.getContractFactory("MockToken");
  const weth = MockToken.attach(tokenAddresses.WETH);
  await weth.mint(owner.address, ethers.utils.parseUnits("1", 18));

  // approve lexer to spend eth
  await weth.approve(
    contractAddresses.atmAddress,
    ethers.utils.parseUnits("1", 18)
  );

  // open a trader order of 1 eth at market order
  const SapphireTradeOrder = await ethers.getContractFactory(
    "SapphireTradeOrder"
  );
  const sapphireTradeOrder = SapphireTradeOrder.attach(
    contractAddresses.sapphireTradeOrderAddress
  );
  const collateralAmount = ethers.utils.parseEther("1");
  const sizeAmount = ethers.utils.parseEther("10");

  await sapphireTradeOrder.createOrder(
    OrderType.MARKET,
    BigNumber.from("1215990000000000000000"),
    BigNumber.from("2"),
    TradeType.LONG,
    sizeAmount,
    weth.address,
    collateralAmount,
    collateralAmount
  );
  return;

  // execute the position
  const feedingPairs = [2];
  const feedingPrices = [ethers.utils.parseEther("1300")];
  const callbackAddress = sapphireTradeOrder.address;
  // get the latest order
  const orderId = await sapphireTradeOrder.tokenOfOwnerByIndex(
    owner.address,
    0
  );

  const callbackSignature = sapphireTradeOrder.interface.encodeFunctionData(
    "executeOrder",
    [orderId]
  );

  const tx = await simplePriceFeed.setPairsLatestPricesWithCallback(
    feedingPairs,
    feedingPrices,
    callbackAddress,
    callbackSignature
  );
  await tx.wait();
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
