// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* ISimplePriceFeed.sol
This contract is used to feed, get and guard the price of a ERC20 token
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

  struct Token {
    bool isTokenAvaliable;
    bool isTokenFeedable;
    uint256 latestRound;
    mapping(uint256 => Price) prices;
  }

  function decimals() external pure returns (uint256);

  function setLatestPrice(
    address _token,
    uint256 _highPrice,
    uint256 _lowPrice
  ) external;

  function getLatestPriceData(address _token, uint256 _roundId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  function getLatestPrice(address _token, Spread _s)
    external
    view
    returns (uint256);
}
