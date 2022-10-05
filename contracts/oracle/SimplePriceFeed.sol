// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SimplePriceFeed.sol
This contract is used to feed, get and guard the price of a ERC20 token
*/

import "./ISimplePriceFeed.sol";

contract SimplePriceFeed is ISimplePriceFeed {
  event PriceSubmitted(
    address indexed token,
    uint256 roundId,
    uint256 highPrice,
    uint256 lowPrice
  );

  mapping(address => Token) public tokens;

  function decimals() external pure returns (uint256) {
    return 18;
  }

  function setLatestPrice(
    address _token,
    uint256 _highPrice,
    uint256 _lowPrice
  ) external {
    tokens[_token].prices[tokens[_token].latestRound].price[
      Spread.HIGH
    ] = _highPrice;
    tokens[_token].prices[tokens[_token].latestRound].price[
      Spread.LOW
    ] = _lowPrice;
    tokens[_token].prices[tokens[_token].latestRound].timestamp = block
      .timestamp;
    emit PriceSubmitted(
      _token,
      tokens[_token].latestRound,
      _highPrice,
      _lowPrice
    );
    tokens[_token].latestRound += 1;
  }

  function getLatestPriceData(address _token, uint256 _roundId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      tokens[_token].prices[_roundId].price[Spread.HIGH],
      tokens[_token].prices[_roundId].price[Spread.LOW],
      tokens[_token].prices[_roundId].timestamp
    );
  }

  function getLatestPrice(address _token, Spread _s)
    external
    view
    returns (uint256)
  {
    if (!tokens[_token].isTokenAvaliable)
      revert("simplePriceFeed: token_unavaliable");
    return tokens[_token].prices[tokens[_token].latestRound - 1].price[_s];
  }

  function addToken(address _token) external {
    tokens[_token].isTokenAvaliable = true;
  }

  function removeToken(address _token) external {
    tokens[_token].isTokenAvaliable = false;
  }
}
