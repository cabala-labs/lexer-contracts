// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBasePool.sol";
import "../token/IPoolToken.sol";
import "../oracle/ISimplePriceFeed.sol";
import "../token/TokenLibs.sol";
import "../atm/IATM.sol";
import "../reward/IBaseReward.sol";
import "../properties/FundWithdrawable.sol";

import "hardhat/console.sol";

abstract contract BasePool is IBasePool, FundWithdrawable {
  using TokenLibs for uint256;

  // ---------- contract storage ----------
  string public name;

  IATM public immutable atm;
  ISimplePriceFeed public immutable priceFeed;

  IPoolToken public poolToken;
  IBaseReward public reward;

  mapping(address => Token) public tokens;
  address[] public includedTokens;

  // ---------- constructor ----------
  constructor(
    string memory _name,
    address _atmAddress,
    address _priceFeedAddress
  ) {
    name = _name;
    atm = IATM(_atmAddress);
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
  }

  // ---------- storage setters ----------
  function setPoolToken(address _poolTokenAddress) external {
    require(
      address(poolToken) == address(0),
      string.concat(name, ":token_addr_exists")
    );
    poolToken = IPoolToken(_poolTokenAddress);
  }

  function setReward(address _rewardAddress) external {
    require(
      address(reward) == address(0),
      string.concat(name, ":reward_addr_exists")
    );
    reward = IBaseReward(_rewardAddress);
  }

  // ---------- action functions ----------
  function stake(
    address _account,
    address _tokenIn,
    uint256 _amountIn,
    uint256 _minAmountOut
  ) external returns (uint256 _amountOut) {
    require(tokens[_tokenIn].tokenActive, "SapPool: token not included");
    // transfer the token
    atm.transferFrom(_tokenIn, msg.sender, address(this), _amountIn);
    // collect staking fee
    uint256 fee = _calStakeFee(_tokenIn, _amountIn);
    reward.collectFee(address(this), _tokenIn, fee, msg.sender);

    // calculate the amount of pool token to mint
    uint256 amountOut = _calPoolTokenOut(_tokenIn, _amountIn - fee);

    // check against the _minAmountOut
    require(amountOut >= _minAmountOut, "SapPool: insufficient_amount_out");

    // mint the token to the _account
    poolToken.mint(_account, amountOut);

    return amountOut;
  }

  function unstake(
    address _account,
    uint256 _amountIn,
    address _tokenOut,
    uint256 _minAmountOut
  ) external returns (uint256 _amountOut) {
    require(
      tokens[_tokenOut].tokenActive,
      string.concat(name, ":token not included")
    );

    // calculate the amount of pool token to unstake
    uint256 amountOut = _calTokenOut(_tokenOut, _amountIn);

    // calculate and collect the fee
    uint256 fee = _calUnstakeFee(_tokenOut, amountOut);
    reward.collectFee(address(this), _tokenOut, fee, msg.sender);

    // check against the _minAmountOut
    amountOut = amountOut - fee;
    require(
      amountOut >= _minAmountOut,
      string.concat(name, ":insufficient_amount_out")
    );

    // burn the pool token from msg.sender
    poolToken.burn(msg.sender, _amountIn);

    // transfer the token to the _account
    atm.transferFrom(_tokenOut, address(this), _account, amountOut);

    return amountOut;
  }

  function addToken(address _token, uint256 _targetAmount) external {
    require(!tokens[_token].tokenActive, string.concat(name, ":token_exists"));
    tokens[_token].tokenActive = true;
    tokens[_token].targetAmount = _targetAmount;
    includedTokens.push(_token);
  }

  function rmvToken(address _token) external {
    require(
      tokens[_token].tokenActive,
      string.concat(name, ":token_not_exists")
    );
    tokens[_token].tokenActive = false;
    for (uint256 i = 0; i < includedTokens.length; i++) {
      if (includedTokens[i] == _token) {
        includedTokens[i] = includedTokens[includedTokens.length - 1];
        includedTokens.pop();
        break;
      }
    }
  }

  function reserveLiquidity(address token, uint256 amount) external {
    require(
      tokens[token].tokenActive,
      string.concat(name, ":token_not_exists")
    );
    require(
      IERC20(token).balanceOf(address(this)) >=
        tokens[token].reservedAmount + amount,
      string.concat(name, ":reserve_exceeds_balance")
    );
    tokens[token].reservedAmount += amount;
  }

  // ---------- view functions ----------
  function getTokenTargetAmount(address _token)
    external
    view
    returns (uint256)
  {
    return tokens[_token].targetAmount;
  }

  function getTokenReservedAmount(address _token)
    external
    view
    returns (uint256 _fee)
  {
    return tokens[_token].reservedAmount;
  }

  function isTokenActive(address _token)
    external
    view
    returns (bool _isActive)
  {
    return tokens[_token].tokenActive;
  }

  function calStakeFee(address _token, uint256 _amountIn)
    external
    view
    returns (uint256 _fee)
  {
    return _calStakeFee(_token, _amountIn);
  }

  function calUnstakeFee(address _token, uint256 _amountIn)
    external
    view
    returns (uint256 _fee)
  {
    return _calUnstakeFee(_token, _amountIn);
  }

  function getPoolAssetBalance(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256)
  {
    return _getPoolAssetBalance(s);
  }

  function getPoolTokenPrice(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256)
  {
    return _getPoolTokenPrice(s);
  }

  // ---------- internal helpers ----------
  function _getPoolAssetBalance(ISimplePriceFeed.Spread s)
    internal
    view
    returns (uint256)
  {
    uint256 poolTotalBalance = 0;
    for (uint256 i = 0; i < includedTokens.length; i++) {
      // get the balance of the token in the pool
      uint256 tokenBalance = IERC20(includedTokens[i]).balanceOf(address(this));

      // normalize the token balance
      tokenBalance = tokenBalance.normalizeDecimal(includedTokens[i]);

      // get the USD value of the token
      uint256 tokenPrice = priceFeed.getTokenLatestPrice(includedTokens[i], s);

      // add the USD value of the token to the total pool balance
      poolTotalBalance += tokenBalance.getSize(tokenPrice);
    }
    return poolTotalBalance;
  }

  function _getPoolTokenPrice(ISimplePriceFeed.Spread s)
    internal
    view
    returns (uint256)
  {
    // in case of no token has been minted
    // the price will always be 1 USD
    if (poolToken.totalSupply() == 0) return 1e18;
    return (_getPoolAssetBalance(s) * 1e18) / poolToken.totalSupply();
  }

  function _calStakeFee(address _tokenIn, uint256 _amountIn)
    internal
    view
    virtual
    returns (uint256);

  function _calUnstakeFee(address _tokenOut, uint256 _amountIn)
    internal
    view
    virtual
    returns (uint256);

  function _calPoolTokenOut(address _tokenIn, uint256 _amountIn)
    internal
    view
    returns (uint256 _amountOut)
  {
    uint256 tokenInPrice = priceFeed.getTokenLatestPrice(
      _tokenIn,
      ISimplePriceFeed.Spread.LOW
    );

    uint256 poolTokenPrice = _getPoolTokenPrice(ISimplePriceFeed.Spread.HIGH);

    uint256 amountOut = _amountIn
      .normalizeDecimal(_tokenIn)
      .getSize(tokenInPrice)
      .getAmount(poolTokenPrice);

    return amountOut;
  }

  function _calTokenOut(address _tokenOut, uint256 _amountIn)
    internal
    view
    returns (uint256 _amountOut)
  {
    // get the price of the _tokenOut
    uint256 tokenOutPrice = priceFeed.getTokenLatestPrice(
      _tokenOut,
      ISimplePriceFeed.Spread.LOW
    );

    // get the price of the poolToken
    uint256 poolTokenPrice = _getPoolTokenPrice(ISimplePriceFeed.Spread.HIGH);

    // calculate the amount of _tokenOut to transfer
    uint256 amountOut = _amountIn
      .getSize(poolTokenPrice)
      .getAmount(tokenOutPrice)
      .toTokenDecimal(_tokenOut);

    return amountOut;
  }
}
