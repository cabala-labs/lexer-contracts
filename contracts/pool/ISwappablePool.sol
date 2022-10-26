// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface ISwappablePool {
  function swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256 _amountOut);

  function swapTokenWithoutFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256 _amountOut, uint256 _fee);

  function calSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256 _fee);

  //   function createSwapOrder(
  //     address _tokenIn,
  //     address _tokenOut,
  //     uint256 _amountIn,
  //     uint256 _minAmountOut
  //   ) external returns (uint256 _orderId);

  //   function executeSwapOrder(uint256 _orderId) external;
}
