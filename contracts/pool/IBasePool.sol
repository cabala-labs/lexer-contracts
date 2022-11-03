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
    address indexed token,
    address indexed account,
    uint256 amountIn,
    uint256 amountOut
  );
  event TokenUnstaked(
    address indexed token,
    address indexed account,
    uint256 amountOut,
    uint256 amountIn
  );
  event CollectStakeFee(
    address indexed account,
    address indexed token,
    uint256 amount
  );
  event CollectUnstakeFee(
    address indexed account,
    address indexed token,
    uint256 amount
  );

  // ---------- action functions ----------
  function stake(
    address buyer,
    address tokenIn,
    uint256 amountIn,
    uint256 minAmountOut
  ) external returns (uint256 amountOut);

  function unstake(
    address seller,
    uint256 amountIn,
    address tokenOut,
    uint256 minAmountOut
  ) external returns (uint256 tokenAmountOut);

  function addToken(address token, uint256 targetAmount) external;

  function rmvToken(address token) external;

  function reserveLiquidity(address token, uint256 amount) external;

  // ---------- view functions ----------
  function getTokenTargetAmount(address token) external view returns (uint256);

  function getTokenReservedAmount(address token)
    external
    view
    returns (uint256 fee);

  function isTokenActive(address token) external view returns (bool isActive);

  function calStakeFee(address token, uint256 amountIn)
    external
    view
    returns (uint256 fee);

  function calUnstakeFee(address token, uint256 amountIn)
    external
    view
    returns (uint256 fee);

  function getPoolAssetBalance(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256 balance);

  function getPoolTokenPrice(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256 price);
}
