// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* ISimplePriceFeed.sol
This contract is used to feed, get and guard the price of a pair
*/

interface ISimplePriceFeed {
  enum Spread {
    HIGH,
    LOW
  }

  struct Price {
    uint256 timestamp;
    mapping(Spread => uint256) price;
  }

  struct Pair {
    bool isPairAvaliable;
    bool isPairFeedable;
    uint256 latestRound;
    mapping(uint256 => Price) prices;
  }

  event PriceSubmitted(
    uint256 indexed pair,
    uint256 roundId,
    uint256 highPrice,
    uint256 lowPrice
  );

  function decimals() external pure returns (uint256);

  function setPairLatestPrice(
    uint256 _pair,
    uint256 _highPrice,
    uint256 _lowPrice
  ) external;

  function getPairLatestPriceData(uint256 _pair, uint256 _roundId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getTokenLatestPrice(address _token, Spread _S)
    external
    view
    returns (uint256);

  function getPairLatestPrice(uint256 _pair, Spread _s)
    external
    view
    returns (uint256);
}
