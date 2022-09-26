// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICommon.sol";

interface ISapphirePool is ICommon {
  function getPoolAssetBalance(Spread s) external view returns (uint256);

  function getPoolTokenBalance() external view returns (uint256);

  function getPoolTokenPrice(Spread s) external view returns (uint256);

  function stake(
    address _buyer,
    address _token,
    uint256 _amount // denoted in _token
  ) external;

  function unstake(
    address _seller,
    address _token,
    uint256 _amount // denoted in _token
  ) external;
}
