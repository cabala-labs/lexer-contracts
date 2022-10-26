// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "../pool/BasePool.sol";
import "../pool/ISwappablePool.sol";

contract SapphirePool is BasePool, ISwappablePool {
  // ---------- contract storage ----------

  // ---------- constructor ----------
  constructor(address _priceFeedAddress, address _atmAddress)
    BasePool("SapPool", _priceFeedAddress, _atmAddress)
  {}

  // ---------- storage setters ----------

  // ---------- action functions ----------
  function swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256 _amountOut) {}

  function swapTokenWithoutFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256 _amountOut, uint256 _fee) {}

  // ---------- view functions ----------
  function calSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256 _fee) {
    return _calSwapFee(_tokenIn, _tokenOut, _amountIn);
  }

  // ---------- internal helpers ----------
  function _calStakeFee(address _tokenIn, uint256 _amountIn)
    internal
    view
    override
    returns (uint256)
  {
    return 0;
  }

  function _calUnstakeFee(address _tokenOut, uint256 _amountIn)
    internal
    view
    override
    returns (uint256)
  {
    return 0;
  }

  function _calSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal view returns (uint256 _fee) {}
}
