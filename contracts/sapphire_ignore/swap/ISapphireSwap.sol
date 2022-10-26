// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../../oracle/ISimplePriceFeed.sol";
import "../../interfaces/FundWithdrawable.sol";

interface ISapphireSwap {
  //   function createSwapTokenOrder(
  //     address _tokenIn,
  //     address _tokenOut,
  //     uint256 _amountIn,
  //     uint256 _minSapphireOut
  //   ) external returns (uint256);

  enum FeeCollectIn {
    IN,
    OUT
  }

  function swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256);

  function swapTokenWithoutFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256);

  function calculateSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256);

  function getSwapInfo(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    FeeCollectIn _FeeCollectIn
  ) external view returns (uint256, uint256);
}
