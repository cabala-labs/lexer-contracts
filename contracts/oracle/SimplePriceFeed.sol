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

  constructor() {}

  function decimals() external pure returns (uint256) {
    return 8;
  }

  function setLatestPrice(address _token, uint256[2] calldata _price) external {
    tokens[_token].prices[tokens[_token].latestRound].price = _price;
    emit PriceSubmitted(
      _token,
      tokens[_token].latestRound,
      _price[0],
      _price[1]
    );
    tokens[_token].latestRound += 1;
  }

  function getLatestPrice(address _token) external view returns (Price memory) {
    return tokens[_token].prices[tokens[_token].latestRound - 1];
  }

  function addToken(address _token) external {
    tokens[_token].isTokenAvaliable = true;
  }

  function removeToken(address _token) external {
    tokens[_token].isTokenAvaliable = false;
  }
}
