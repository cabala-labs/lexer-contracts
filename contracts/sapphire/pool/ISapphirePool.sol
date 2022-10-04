// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../oracle/ISimplePriceFeed.sol";

interface ISapphirePool {
  function getPoolAssetBalance(ISimplePriceFeed.Spread _s)
    external
    view
    returns (uint256);

  function getPoolTokenPrice(ISimplePriceFeed.Spread _s)
    external
    view
    returns (uint256);

  function stake(
    address _account,
    address _token,
    uint256 _amount,
    uint256 _minSapphireOut
  ) external;

  function unstake(
    address _account,
    address _token,
    uint256 _amount,
    uint256 _mintTokenOut
  ) external;
}
