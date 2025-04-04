// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IBaseTrade.sol";

import "../token/TokenLibs.sol";
import "../oracle/ISimplePriceFeed.sol";
import "../atm/IATM.sol";
import "../pool/IBasePool.sol";
import "../pool/ISwappablePool.sol";
import "../reward/IBaseReward.sol";
import "../ERC721T/ERC721T.sol";
import "../properties/FundWithdrawable.sol";

import "hardhat/console.sol";

abstract contract BaseTrade is IBaseTrade, ERC721T, FundWithdrawable {
  using TokenLibs for uint256;
  // ---------- contract storage ----------
  string public contractName;

  ISimplePriceFeed priceFeed;
  IATM atm;
  IBasePool pool;
  ISwappablePool swap;
  IBaseReward reward;

  mapping(address => BorrowRate) public borrowRates;
  uint256 public borrowInterval = 3600;
  mapping(uint256 => bool) public availablePairs;
  mapping(uint256 => Position) internal positions;
  uint256 liquidationThreshold = 97 * 1e16; // 97% [0.97] * 1e18 = 97 * 1e16

  // ---------- constructor ----------
  constructor(
    string memory _contractName,
    address _atmAddress,
    address _priceFeedAddress
  )
    ERC721T(
      string.concat(_contractName, "_Position"),
      string.concat(_contractName, "_POS")
    )
  {
    contractName = _contractName;
    atm = IATM(_atmAddress);
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
  }

  // ---------- storage setters ----------
  function setPool(address _poolAddress) external {
    require(
      address(pool) == address(0),
      string.concat(contractName, ":pool_addr_exists")
    );
    pool = IBasePool(_poolAddress);
  }

  function setSwap(address _swapAddress) external {
    require(
      address(swap) == address(0),
      string.concat(contractName, ":swap_addr_exists")
    );
    swap = ISwappablePool(_swapAddress);
  }

  function setReward(address _rewardAddress) external {
    require(
      address(reward) == address(0),
      string.concat(contractName, ":reward_addr_exists")
    );
    reward = IBaseReward(_rewardAddress);
  }

  function addPair(uint256 _pair) external {
    availablePairs[_pair] = true;
  }

  function removePair(uint256 _pair) external {
    availablePairs[_pair] = false;
  }

  // ---------- action functions ----------
  function createPosition(
    address _account,
    uint256 _indexPair,
    TradeType _tradeType,
    uint256 _size,
    address _depositToken,
    uint256 _depositAmount
  ) external {
    // receive collateral
    atm.transferFrom(_depositToken, msg.sender, address(this), _depositAmount);

    // check if swap is required
    address collateralToken = _getCollateralToken(_indexPair, _tradeType);

    // init a new position
    Position memory newPosition = Position({
      indexPair: _indexPair,
      tradeType: _tradeType,
      entryPrice: priceFeed.getPairLatestPrice(
        _indexPair,
        _tradeType == TradeType.LONG
          ? ISimplePriceFeed.Spread.HIGH
          : ISimplePriceFeed.Spread.LOW
      ),
      size: _size,
      totalCollateralBalance: 0,
      totalCollateralAmount: _depositAmount,
      exitPrice: 0,
      incurredFee: _calOpenPositionFee(_indexPair, _size),
      lastBorrowRate: borrowRates[collateralToken].accumulator
    });

    // emit debit open position fee event
    emit DebitOpenPositionFee(totalMinted(), newPosition.incurredFee);

    if (collateralToken != _depositToken) {
      // swap collateral and debit the fee
      (uint256 amountOut, uint256 fee) = swap.swapTokenWithoutFee(
        _depositToken,
        collateralToken,
        _depositAmount
      );

      newPosition.totalCollateralAmount = amountOut;
      newPosition.incurredFee += fee;

      // emit debit swap fee event
      emit DebitBorrowFee(totalMinted(), fee);
    }

    // take a snapshot of the USD value of the collateral
    uint256 collateralTokenPrice = priceFeed.getTokenLatestPrice(
      collateralToken,
      ISimplePriceFeed.Spread.LOW
    );
    newPosition.totalCollateralBalance = newPosition
      .totalCollateralAmount
      .normalizeDecimal(collateralToken)
      .getSize(collateralTokenPrice);

    // reserve the liquidity: size (in index token) to the amount of collateral token
    {
      address tradingToken = _getTradingToken(_indexPair);
      if (tradingToken == collateralToken) {
        pool.reserveLiquidity(collateralToken, _size);
      } else {
        // get the price of the trading token
        uint256 tradingTokenPrice = priceFeed.getTokenLatestPrice(
          tradingToken,
          _tradeType == TradeType.LONG
            ? ISimplePriceFeed.Spread.LOW
            : ISimplePriceFeed.Spread.HIGH
        );
        uint256 reservedAmount = _size
          .normalizeDecimal(tradingToken)
          .getSize(tradingTokenPrice)
          .getAmount(collateralTokenPrice)
          .toTokenDecimal(collateralToken);
        pool.reserveLiquidity(collateralToken, reservedAmount);
      }
    }

    // mint a new position NFT to the user
    _mint(_account, newPosition);

    // emit open position event
    emit PositionCreated(
      _account,
      totalMinted() - 1,
      _indexPair,
      _tradeType,
      newPosition.entryPrice,
      _size,
      newPosition.totalCollateralBalance,
      newPosition.totalCollateralAmount
    );
  }

  function closePosition(
    uint256 _tokenId,
    address _withdrawToken,
    address _withdrawAddress
  ) external {
    (address collateralToken, uint256 withdrawAmount) = _closePosition(
      _tokenId
    );

    // swap the asset if needed
    if (_withdrawToken != collateralToken) {
      withdrawAmount = swap.swapToken(
        collateralToken,
        _withdrawToken,
        withdrawAmount
      );
    }

    IERC20(_withdrawToken).transfer(_withdrawAddress, withdrawAmount);
  }

  function liquidatePosition(uint256 _tokenId) external {
    require(_isPositionLiquidatable(_tokenId), "position_not_liquidatable");

    // store the owner of the address
    address owner = ownerOf(_tokenId);

    (address collateralToken, uint256 withdrawAmount) = _closePosition(
      _tokenId
    );

    // credit to the liquidator

    // emit liquidate position event
    emit PositionLiquidated(_tokenId);
    // transfer the rest to the owner
    IERC20(collateralToken).transfer(owner, withdrawAmount);
  }

  function updateBorrowFee(uint256 indexPair) external {}

  // ---------- view functions ----------
  function getCollateralToken(uint256 _tokenId)
    external
    view
    returns (address)
  {
    Position memory position = positions[_tokenId];
    return _getCollateralToken(position.indexPair, position.tradeType);
  }

  function getCollateralToken(uint256 _indexPair, TradeType _tradeType)
    external
    view
    returns (address)
  {
    return _getCollateralToken(_indexPair, _tradeType);
  }

  function calPositionPnL(uint256 tokenId, bool withFee)
    external
    view
    returns (bool, uint256)
  {
    return _calPositionPnL(tokenId, withFee);
  }

  function isPositionLiquidatable(uint256 _tokenId)
    external
    view
    returns (bool)
  {
    return _isPositionLiquidatable(_tokenId);
  }

  function getPositionMetadata(uint256 _tokenId)
    external
    view
    returns (Position memory)
  {
    return positions[_tokenId];
  }

  // ---------- internal functions ----------
  function _closePosition(uint256 _tokenId)
    internal
    returns (address, uint256)
  {
    address account = ownerOf(_tokenId);
    // debit the fee for closing position
    _debitClosePositionFee(_tokenId);
    // debit the fee for borrowing
    _debitBorrowFee(_tokenId);

    Position memory position = positions[_tokenId];

    address collateralToken = _getCollateralToken(
      position.indexPair,
      position.tradeType
    );
    // get the price of the collateralToken
    uint256 collateralTokenPrice = priceFeed.getTokenLatestPrice(
      collateralToken,
      ISimplePriceFeed.Spread.LOW
    );

    // collect the fee
    reward.collectFee(
      address(this),
      collateralToken,
      position.incurredFee,
      account
    );

    uint256 pairPrice = priceFeed.getPairLatestPrice(
      position.indexPair,
      ISimplePriceFeed.Spread.LOW
    );

    // burn the position NFT
    _burn(_tokenId, pairPrice);

    // emit close position event
    emit PositionClosed(account, _tokenId, pairPrice);
    // calculate the withdraw amount
    (bool isProfit, uint256 positionPnL) = _calPositionPnL(_tokenId, true);
    uint256 withdrawalAmount = (
      isProfit
        ? position.totalCollateralBalance + positionPnL
        : position.totalCollateralBalance - positionPnL
    ).getAmount(collateralTokenPrice).toTokenDecimal(collateralToken);
    uint256 feeAmount = position
      .incurredFee
      .getAmount(collateralTokenPrice)
      .toTokenDecimal(collateralToken);
    withdrawalAmount = withdrawalAmount - feeAmount;
    uint256 collateralAmount = _getCollateralAmount(_tokenId);
    if (isProfit) {
      console.log("xx", withdrawalAmount, collateralAmount);
      // withdraw the profit into this contract
      atm.transferFrom(
        collateralToken,
        address(pool),
        address(this),
        withdrawalAmount - collateralAmount
      );
      return (collateralToken, withdrawalAmount);
    } else {
      console.log(
        collateralAmount,
        withdrawalAmount,
        collateralAmount - withdrawalAmount
      );
      // send the loss to the pool
      atm.transferFrom(
        collateralToken,
        address(this),
        address(pool),
        collateralAmount - withdrawalAmount
      );
      return (collateralToken, withdrawalAmount);
    }
  }

  function _calOpenPositionFee(uint256 _indexPair, uint256 _size)
    internal
    view
    virtual
    returns (uint256);

  function _calPositionPnL(uint256 _tokenId, bool _withFee)
    internal
    view
    returns (bool isProfit, uint256 positionPnL)
  {
    Position memory position = positions[_tokenId];

    // get the price of the index pair
    uint256 pairPrice = priceFeed.getPairLatestPrice(
      position.indexPair,
      position.tradeType == TradeType.LONG
        ? ISimplePriceFeed.Spread.LOW
        : ISimplePriceFeed.Spread.HIGH
    );

    // check if the position is in profit
    if (
      (position.tradeType == TradeType.LONG &&
        pairPrice >= position.entryPrice) ||
      (position.tradeType == TradeType.SHORT &&
        pairPrice <= position.entryPrice)
    ) {
      isProfit = true;
    }

    console.log("pairPrice", pairPrice, position.entryPrice, isProfit);

    // find the trading token of the pair
    address tradingToken = _getTradingToken(position.indexPair);

    // if long & profit or short & loss => current price > entry price
    if (
      (position.tradeType == TradeType.LONG && isProfit) ||
      (position.tradeType == TradeType.SHORT && !isProfit)
    ) {
      positionPnL = position.size.normalizeDecimal(tradingToken).getSize(
        pairPrice - position.entryPrice
      );
    }

    // if long & loss or short & profit => current price < entry price
    if (
      (position.tradeType == TradeType.LONG && !isProfit) ||
      (position.tradeType == TradeType.SHORT && isProfit)
    ) {
      positionPnL = position.size.normalizeDecimal(tradingToken).getSize(
        position.entryPrice - pairPrice
      );
    }

    if (_withFee) {
      // in loss, add the fee to positionPnL
      if (!isProfit) {
        positionPnL += position.incurredFee;
      }

      // in profit, if the positionPnL > fee
      if (isProfit && positionPnL > position.incurredFee) {
        positionPnL -= position.incurredFee;
      }

      // in profit, if the positionPnL < fee
      if (isProfit && positionPnL < position.incurredFee) {
        positionPnL = position.incurredFee - positionPnL;
        isProfit = false;
      }
    }
  }

  function _getCollateralToken(uint256 _indexPair, TradeType _tradeType)
    internal
    view
    virtual
    returns (address);

  function _getCollateralAmount(uint256 _tokenId)
    internal
    view
    virtual
    returns (uint256);

  function _debitClosePositionFee(uint256 _tokenId) internal virtual;

  function _debitBorrowFee(uint256 _tokenId) internal {
    Position memory position = positions[_tokenId];
    uint256 currentRate = borrowRates[
      _getCollateralToken(position.indexPair, position.tradeType)
    ].accumulator;
    uint256 fee = ((currentRate - position.lastBorrowRate) * position.size) /
      1e18;
    position.incurredFee += fee;
    position.lastBorrowRate = currentRate;
    emit DebitBorrowFee(_tokenId, fee);
  }

  function _mint(address _to, Position memory _position) internal {
    uint256 tokenId = totalMinted();
    positions[tokenId] = _position;
    super._safeMint(_to, tokenId);
  }

  function _burn(uint256 _tokenId, uint256 _pairPrice) internal {
    positions[_tokenId].exitPrice = _pairPrice;
    super._burn(_tokenId);
  }

  function _isPositionLiquidatable(uint256 _tokenId)
    internal
    view
    returns (bool)
  {
    // find the pnl of the position
    (bool isProfit, uint256 positionPnL) = _calPositionPnL(_tokenId, false);

    console.log(
      "isPositionLiquidatable",
      isProfit,
      positionPnL,
      positions[_tokenId].totalCollateralBalance.getRatio(liquidationThreshold)
    );
    // if the position is in loss and lost more than the threshold
    return
      !isProfit &&
      positionPnL >=
      positions[_tokenId].totalCollateralBalance.getRatio(liquidationThreshold);
  }

  function _getTradingToken(uint256 _indexPair)
    internal
    view
    virtual
    returns (address);
}
