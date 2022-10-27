// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../oracle/ISimplePriceFeed.sol";

interface IBasePool {
  // ---------- custom datatypes ----------
  struct Token {
    uint256 targetAmount;
    uint256 reservedAmount;
    bool tokenActive;
  }

  // ---------- events ----------
  event TokenStaked(
    address indexed _token,
    address indexed _account,
    uint256 _amountIn,
    uint256 _amountOut
  );
  event TokenUnstaked(
    address indexed _token,
    address indexed _account,
    uint256 _amountOut,
    uint256 _amountIn
  );
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

  // ---------- action functions ----------
  function stake(
    address _buyer,
    address _tokenIn,
    uint256 _amountIn,
    uint256 _minAmountOut
  ) external returns (uint256 _amountOut);

  function unstake(
    address _seller,
    uint256 _amountIn,
    address _tokenOut,
    uint256 _minAmountOut
  ) external returns (uint256 _tokenAmountOut);

  function addToken(address _token, uint256 _targetAmount) external;

  function rmvToken(address _token) external;

  // ---------- view functions ----------
  function getTokenTargetAmount(address _token) external view returns (uint256);

  function getTokenReservedAmount(address _token)
    external
    view
    returns (uint256 _fee);

  function isTokenActive(address _token) external view returns (bool _isActive);

  function calStakeFee(address _token, uint256 _amountIn)
    external
    view
    returns (uint256 _fee);

  function calUnstakeFee(address _token, uint256 _amountIn)
    external
    view
    returns (uint256 _fee);

  function getPoolAssetBalance(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256 _balance);

  function getPoolTokenPrice(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256 _price);
}
