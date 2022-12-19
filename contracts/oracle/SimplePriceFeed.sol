// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* SimplePriceFeed.sol
This contract is used to feed, get and guard the price of pairs
*/

import "@openzeppelin/contracts/utils/Address.sol";
import "./ISimplePriceFeed.sol";
import "hardhat/console.sol";

contract SimplePriceFeed is ISimplePriceFeed {
  mapping(uint256 => Pair) public pairs;
  mapping(address => uint256) public tokenToPair;

  function decimals() external pure returns (uint256) {
    return 18;
  }

  function setPairsLatestPricesWithCallback(
    uint256[] memory _pairs,
    uint256[] memory _prices,
    address _callbackAddress,
    bytes memory _callbackSignature,
    uint256 _callbackValue
  ) external {
    for (uint256 i = 0; i < _pairs.length; i++) {
      _setPairPrice(_pairs[i], _prices[i]);
    }
    Address.functionCallWithValue(
      _callbackAddress,
      _callbackSignature,
      _callbackValue
    );
  }

  function setPairsLatestPrices(uint256[] memory _pair, uint256[] memory _price)
    external
  {
    for (uint256 i = 0; i < _pair.length; i++) {
      _setPairPrice(_pair[i], _price[i]);
    }
  }

  function setPairLatestPrice(uint256 _pair, uint256 _price) external {
    _setPairPrice(_pair, _price);
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

  function getTokenLatestPrice(address _token, Spread _s)
    external
    view
    returns (uint256)
  {
    require(tokenToPair[_token] != 0, "simplePriceFeed:token_not_mapped");
    return
      pairs[tokenToPair[_token]]
        .prices[pairs[tokenToPair[_token]].latestRound - 1]
        .price[_s];
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

  function _setPairPrice(uint256 _pair, uint256 _price) internal {
    require(pairs[_pair].isPairAvaliable, "simplePriceFeed:pair_unavaliable");
    uint256 newRound = pairs[_pair].latestRound + 1;
    // check if the pair needs to be checked against Chainlink
    if (pairs[_pair].shouldCheckChainlink) {
      //todo chainlink check
      return;
    } else {
      pairs[_pair].prices[newRound].price[Spread.HIGH] = _price;
      pairs[_pair].prices[newRound].price[Spread.LOW] = _price;
    }

    pairs[_pair].latestRound += 1;
    pairs[_pair].prices[pairs[_pair].latestRound].timestamp = block.timestamp;
    emit PriceSubmitted(
      _pair,
      pairs[_pair].latestRound,
      pairs[_pair].prices[newRound].price[Spread.HIGH],
      pairs[_pair].prices[newRound].price[Spread.LOW]
    );
  }
}
