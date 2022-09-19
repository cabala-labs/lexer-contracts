// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* ISimplePriceFeed.sol
This contract is used to feed, get and guard the price of a ERC20 token
*/

interface ISimplePriceFeed {
  struct Price {
    uint256 timestamp;
    uint256[2] price;
  }

  struct Token {
    bool isTokenAvaliable;
    bool isTokenFeedable;
    uint256 latestRound;
    mapping(uint256 => Price) prices;
  }

  function decimals() external pure returns (uint256);

  function setLatestPrice(address _token, uint256[2] calldata _price) external;

  function getLatestPrice(address _token) external view returns (Price memory);
}
