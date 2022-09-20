// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ISapphirePool {
  function getPoolBalance() external view returns (uint256);

  function getTokenBalance() external view returns (uint256);

  function getDiamondPrice() external view returns (uint256);

  function stake(
    address _buyer,
    address _token,
    uint256 _amount // denoted in _token
  ) external;

  function unstake() external;
}
