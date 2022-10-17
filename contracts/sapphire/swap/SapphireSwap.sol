// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../token/TokenLibs.sol";
import "../../oracle/ISimplePriceFeed.sol";
import "../pool/ISapphirePool.sol";
import "../reward/ISapphireReward.sol";
import "hardhat/console.sol";

import "./ISapphireSwap.sol";

contract SapphireSwap is ISapphireSwap {
  using TokenLibs for uint256;
  ISimplePriceFeed priceFeed;
  ISapphirePool sapphirePool;
  ISapphireReward sapphireReward;

  constructor(address _priceFeedAddress, address _sapphirePoolAddress) {
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
    sapphirePool = ISapphirePool(_sapphirePoolAddress);
  }

  function setContract() external {
    sapphireReward = ISapphireReward(sapphirePool.sapphireRewardAddress());
  }

  function swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256) {
    // calculate fee
    uint256 fee = 0;
    // collect fee
    sapphireReward.collectFee(address(this), _tokenIn, fee, msg.sender);
    return _swapToken(_tokenIn, _tokenOut, _amountIn - fee);
  }

  function swapTokenWithoutFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256) {
    return _swapToken(_tokenIn, _tokenOut, _amountIn);
  }

  function _swapToken(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal returns (uint256) {
    // get the min price of the _tokenIn
    uint256 tokenInPrice = priceFeed.getLatestPrice(
      _tokenIn,
      ISimplePriceFeed.Spread.LOW
    );
    // get the max price of the _tokenOut
    uint256 tokenOutPrice = priceFeed.getLatestPrice(
      _tokenOut,
      ISimplePriceFeed.Spread.HIGH
    );
    // calculate the amount of _tokenOut to send to the _seller
    uint256 tokenOutAmount = _amountIn.getSize(tokenInPrice).getAmount(
      tokenOutPrice
    );
    // send the _tokenIn to the pool
    IERC20(_tokenIn).transferFrom(msg.sender, address(sapphirePool), _amountIn);
    // send the _tokenOut to the _seller
    IERC20(_tokenOut).transferFrom(
      address(sapphirePool),
      msg.sender,
      tokenOutAmount
    );
    return tokenOutAmount;
  }

  function calculateSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) external returns (uint256) {
    return _calculateSwapFee(_tokenIn, _tokenOut, _amountIn);
  }

  function _calculateSwapFee(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn
  ) internal view returns (uint256) {
    return 0;
  }

  function getSwapInfo(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    FeeCollectIn _FeeCollectIn
  )
    external
    view
    returns (
      uint256, // amountOut
      uint256 // fee
    )
  {
    // get the min price of the _tokenIn
    uint256 tokenInPrice = priceFeed.getLatestPrice(
      _tokenIn,
      ISimplePriceFeed.Spread.LOW
    );
    // get the max price of the _tokenOut
    uint256 tokenOutPrice = priceFeed.getLatestPrice(
      _tokenOut,
      ISimplePriceFeed.Spread.HIGH
    );
    // calculate fee
    uint256 fee = 0;

    if (_FeeCollectIn == FeeCollectIn.IN) {
      _amountIn -= fee;
    }
    // calculate the amount of _tokenOut to send to the _seller
    uint256 tokenOutAmount = _amountIn
      .normalizeDecimal(_tokenIn)
      .getSize(tokenInPrice)
      .getAmount(tokenOutPrice)
      .toTokenDecimal(_tokenOut);
    if (_FeeCollectIn == FeeCollectIn.OUT) {
      tokenOutAmount -= fee;
    }
    return (tokenOutAmount, fee);
  }

  function withdrawToken(address _token, uint256 _amount) external {
    console.log("pool has", IERC20(_token).balanceOf(address(sapphirePool)));
    console.log("transfer", _amount);
    IERC20(_token).transfer(msg.sender, _amount);
  }
}
