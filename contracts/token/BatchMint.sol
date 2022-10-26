// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

import "./MockToken.sol";

contract BatchMint {
  MockToken public wethAddress;
  MockToken public usdcAddress;
  MockToken public wbtcAddress;
  uint256 roundId = 1;

  mapping(address => uint256) public claimedRound;

  constructor(
    address _wethAddress,
    address _usdcAddress,
    address _wbtcAddress
  ) {
    wethAddress = MockToken(_wethAddress);
    usdcAddress = MockToken(_usdcAddress);
    wbtcAddress = MockToken(_wbtcAddress);
  }

  function getToken() external {
    require(claimedRound[msg.sender] < roundId, "Address already Claimed");
    claimedRound[msg.sender] = roundId;
    (wethAddress).mint(tx.origin, 6 * 1e18);
    (usdcAddress).mint(tx.origin, 6000 * 1e6);
    (wbtcAddress).mint(tx.origin, 6 * 1e7);
  }

  function setUSDCAddress(address _usdcAddress) external {
    usdcAddress = MockToken(_usdcAddress);
  }

  function setWBTCAddress(address _wbtcAddress) external {
    wbtcAddress = MockToken(_wbtcAddress);
  }

  function setWETHAddress(address _wethAddress) external {
    wethAddress = MockToken(_wethAddress);
  }

  function setRoundId(uint256 _roundId) external {
    roundId = _roundId;
  }
}
