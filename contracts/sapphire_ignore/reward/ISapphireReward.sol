// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface ISapphireReward {
  function collectFee(
    address _from,
    address _tokenAddress,
    uint256 _tokenAmount,
    address _feePayer
  ) external;

  function creditReward(address _account) external;

  function claimReward(address _account) external;
}
