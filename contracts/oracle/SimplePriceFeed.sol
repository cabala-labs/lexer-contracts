// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* SimplePriceFeed.sol
This contract is used to feed, get and guard the price of a ERC20 pair
*/

import "./ISimplePriceFeed.sol";
import "hardhat/console.sol";

contract SimplePriceFeed is ISimplePriceFeed {
  mapping(uint256 => Pair) public pairs;
  mapping(address => uint256) public tokenToPair;

  function decimals() external pure returns (uint256) {
    return 18;
  }

  function setPairLatestPrice(
    uint256 _pair,
    uint256 _highPrice,
    uint256 _lowPrice
  ) external {
    require(pairs[_pair].isPairAvaliable, "simplePriceFeed:pair_unavaliable");
    pairs[_pair].prices[pairs[_pair].latestRound].price[
      Spread.HIGH
    ] = _highPrice;
    pairs[_pair].prices[pairs[_pair].latestRound].price[Spread.LOW] = _lowPrice;
    pairs[_pair].prices[pairs[_pair].latestRound].timestamp = block.timestamp;
    emit PriceSubmitted(_pair, pairs[_pair].latestRound, _highPrice, _lowPrice);
    pairs[_pair].latestRound += 1;
  }

  function getPairLatestPriceData(uint256 _pair, uint256 _roundId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    require(pairs[_pair].isPairAvaliable, "simplePriceFeed:pair_unavaliable");
    return (
      pairs[_pair].prices[_roundId].price[Spread.HIGH],
      pairs[_pair].prices[_roundId].price[Spread.LOW],
      pairs[_pair].prices[_roundId].timestamp
    );
  }

  function getPairLatestPrice(uint256 _pair, Spread _s)
    external
    view
    returns (uint256)
  {
    require(pairs[_pair].isPairAvaliable, "simplePriceFeed:pair_unavaliable");
    return pairs[_pair].prices[pairs[_pair].latestRound - 1].price[_s];
  }

  function getTokenLatestPrice(address _token, Spread _S)
    external
    view
    returns (uint256)
  {
    require(tokenToPair[_token] != 0, "simplePriceFeed:token_not_mapped");
    return
      pairs[tokenToPair[_token]]
        .prices[pairs[tokenToPair[_token]].latestRound - 1]
        .price[_S];
  }

  function addPair(uint256 _pair) external {
    require(
      !pairs[_pair].isPairAvaliable,
      "simplePriceFeed:pair_alrd_avaliable"
    );
    pairs[_pair].isPairAvaliable = true;
  }

  function removePair(uint256 _pair) external {
    pairs[_pair].isPairAvaliable = false;
  }

  function mapTokenToPair(address _token, uint256 _pair) external {
    require(pairs[_pair].isPairAvaliable, "simplePriceFeed:pair_unavaliable");
    tokenToPair[_token] = _pair;
  }
}
