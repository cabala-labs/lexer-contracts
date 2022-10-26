// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IBaseReward {
  // ---------- custom datatypes ----------
  // ---------- events ----------
  event CreditRefererReward(address indexed referer, uint256 amount);
  event CreditReferreeReward(address indexed referree, uint256 amount);
  event CreditStakerReward(address indexed staker, uint256 amount);
  event CreditTeamReward(uint256 amount);
  event ClaimReward(address indexed user, uint256 amount);

  // ---------- action functions ----------
  function collectFee(
    address _from,
    address _token,
    uint256 _amount,
    address _feePayer
  ) external;

  function creditReward(address _account) external;

  function claimReward(address _account) external;

  // ---------- view functions ----------
  function getUnclaimedReward(address _account) external view returns (uint256);
}
