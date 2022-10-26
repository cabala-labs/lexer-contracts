// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../oracle/ISimplePriceFeed.sol";
import "../token/ISapphireToken.sol";

interface ISapphirePool {
  struct TokenSetting {
    uint256 targetAmount;
    bool tokenActive;
    uint256 openLongInterest;
    uint256 openShortInterest;
  }

  event CollectStakeFee(
    address indexed _account,
    address indexed _token,
    uint256 _amount
  );
  event CollectUnstakeFee(
    address indexed _account,
    address indexed _token,
    uint256 _amount
  );

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

  function sapphireSwapAddress() external view returns (address);

  function sapphireTradeAddress() external view returns (address);

  function sapphireRewardAddress() external view returns (address);

  function sapphireNFTAddress() external view returns (address);

  function sapphireTokenAddress() external view returns (address);
}
