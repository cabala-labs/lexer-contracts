// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "../pool/BasePool.sol";
import "../pool/ISwappablePool.sol";
import "../oracle/ISimplePriceFeed.sol";

contract SapphirePool is BasePool, ISwappablePool {
  using TokenLibs for uint256;

  // ---------- contract storage ----------

  // ---------- constructor ----------
  constructor(address _priceFeedAddress, address _atmAddress)
    BasePool("SapPool", _atmAddress, _priceFeedAddress)
  {}

  // ---------- storage setters ----------

  // ---------- action functions ----------
  function swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256 _amountOut) {
    // calculate fee
    uint256 fee = 0;
    // collect fee
    reward.collectFee(address(this), _tokenIn, fee, msg.sender);
    return _swapToken(_tokenIn, _tokenOut, _amountIn - fee);
  }

  function swapTokenWithoutFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256 _amountOut, uint256 _fee) {
    return (_swapToken(_tokenIn, _tokenOut, _amountIn), 0);
  }

  // ---------- view functions ----------
  function calSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external view returns (uint256 _fee) {
    return _calSwapFee(_tokenIn, _tokenOut, _amountIn);
  }

  // ---------- internal helpers ----------
  function _swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal returns (uint256 _amountOut) {
    // get the price of _tokenIn
    uint256 tokenInPrice = priceFeed.getTokenLatestPrice(
      _tokenIn,
      ISimplePriceFeed.Spread.LOW
    );

    // get the price of _tokenOut
    uint256 tokenOutPrice = priceFeed.getTokenLatestPrice(
      _tokenOut,
      ISimplePriceFeed.Spread.HIGH
    );

    // get the amount of _tokenIn
    atm.transferFrom(_tokenIn, msg.sender, address(this), _amountIn);

    // calculate the amount of _tokenOut
    _amountOut = _amountIn
      .normalizeDecimal(_tokenIn)
      .getSize(tokenInPrice)
      .getAmount(tokenOutPrice)
      .toTokenDecimal(_tokenOut);

    // transfer the amount of _tokenOut
    IERC20(_tokenOut).transfer(msg.sender, _amountOut);
  }

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
  ) internal view returns (uint256 _fee) {
    return 0;
  }
}
