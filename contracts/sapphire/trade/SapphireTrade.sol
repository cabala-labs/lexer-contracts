// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "../pool//ISapphirePool.sol";
import "./ISapphireTrade.sol";
import "../nft/ISapphireNFT.sol";
import "../../oracle/ISimplePriceFeed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";
import "../../token/TokenLibs.sol";
import "../reward/ISapphireReward.sol";

contract SapphireTrade is ISapphireTrade {
  using TokenLibs for uint256;
  ISimplePriceFeed priceFeed;
  ISapphirePool sapphirePool;
  ISapphireNFT sapphireNFT;
  ISapphireReward sapphireReward;

  struct BorrowRate {
    mapping(TradeType => mapping(uint256 => uint256)) borrowRate;
    uint256 borrowRateUpdatedTimestamp;
    uint256 borrowRateIntervel;
  }
  mapping(address => BorrowRate) public borrowRates;

  mapping(address => uint256) public reservedLiquidity;

  uint256 public openPositionFeeBPS;
  uint256 public closePositionFeeBPS;

  constructor(
    address _priceFeedAddress,
    address _sapphirePoolAddress,
    address _sapphireNFTAddress,
    address _sapphireRewardAddress
  ) {
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
    sapphirePool = ISapphirePool(_sapphirePoolAddress);
    sapphireNFT = ISapphireNFT(_sapphireNFTAddress);
    sapphireReward = ISapphireReward(_sapphireRewardAddress);
  }

  function createPosition(
    address _account,
    address _indexToken,
    TradeType _tradeType,
    uint256 _size,
    address _collateralToken,
    uint256 _collateralAmount
  ) external {
    // get the price of the colleteral token
    uint256 collateralTokenPrice = priceFeed.getLatestPrice(
      _collateralToken,
      ISimplePriceFeed.Spread.LOW
    );

    // balance of the colleteral token
    uint256 collateralBalance = _collateralAmount.getSize(collateralTokenPrice);

    // get the price of the index token
    uint256 indexTokenPrice = priceFeed.getLatestPrice(
      _indexToken,
      _tradeType == TradeType.LONG
        ? ISimplePriceFeed.Spread.HIGH
        : ISimplePriceFeed.Spread.LOW
    );

    // receive collateral from user
    IERC20(_collateralToken).transferFrom(
      _account,
      address(this),
      _collateralAmount
    );

    // calculate the fee for opening position
    uint256 openingFee = _calculateOpenPositionFee(_indexToken, _size);

    // mint a new positon NFT to the user
    uint256 tokenId = sapphireNFT.mint(
      _account,
      SapphirePosition({
        indexToken: _indexToken,
        totalCollateralBalance: collateralBalance,
        size: _size,
        tradeType: _tradeType,
        entryPrice: indexTokenPrice,
        exitPrice: 0,
        incurredFee: openingFee,
        lastBorrowRate: _getLatestBorrowRate(_indexToken, _tradeType)
      })
    );

    // emit event
    emit PositionCreated(
      _account,
      tokenId,
      _indexToken,
      _tradeType,
      indexTokenPrice,
      _size,
      collateralBalance
    );
    emit DebitOpenPositionFee(tokenId, openingFee);
  }

  function closePosition(uint256 _tokenId, address _withdrawToken) external {
    //todo validaiton
    address account = sapphireNFT.ownerOf(_tokenId);
    // debit the fee for closing position
    _debitClosePositionFee(_tokenId);
    // debit the fee for borrowing
    _debitBorrowFee(_tokenId);

    SapphirePosition memory position = sapphireNFT.getPositionMetadata(
      _tokenId
    );

    // get the price of the index token
    uint256 indexTokenPrice = priceFeed.getLatestPrice(
      position.indexToken,
      position.tradeType == TradeType.LONG
        ? ISimplePriceFeed.Spread.LOW
        : ISimplePriceFeed.Spread.HIGH
    );

    // collect the fee
    sapphireReward.collectFee(
      address(this),
      position.indexToken,
      position.incurredFee,
      msg.sender
    );

    // calculate the withdraw amount with pnl in usd value
    (bool isProfit, uint256 positionPnL) = _calculatePositionPnL(
      _tokenId,
      true
    );

    // send the withdraw amount minus fee to user
    //! todo: totalCollateralBalance is in USD and positionPnL is in index token
    uint256 withdrawalAmount = isProfit
      ? position.totalCollateralBalance + positionPnL
      : position.totalCollateralBalance - positionPnL;

    // get the price of the _withdrawToken
    uint256 withdrawalTokenPrice = priceFeed.getLatestPrice(
      _withdrawToken,
      ISimplePriceFeed.Spread.HIGH
    );
    // calculate the withdraw amount in _withdrawToken with respect of the _withdrawToken decimals
    uint256 withdrawAmountInWithdrawToken = withdrawalAmount.toTokenAmount(
      1e18,
      withdrawalTokenPrice
    );
    IERC20(_withdrawToken).transfer(account, withdrawAmountInWithdrawToken);
    // burn the position NFT
    sapphireNFT.burn(_tokenId);

    // emit event
    emit PositionClosed(account, _tokenId, indexTokenPrice);
  }

  function _calculatePositionPnL(uint256 _tokenId, bool _withFee)
    internal
    view
    returns (bool, uint256)
  {
    SapphirePosition memory position = sapphireNFT.getPositionMetadata(
      _tokenId
    );
    // get the price of the index token
    uint256 indexTokenPrice = priceFeed.getLatestPrice(
      position.indexToken,
      position.tradeType == TradeType.LONG
        ? ISimplePriceFeed.Spread.LOW
        : ISimplePriceFeed.Spread.HIGH
    );

    bool isProfit = false;
    if (
      position.tradeType == TradeType.LONG &&
      position.entryPrice <= indexTokenPrice
    ) {
      isProfit = true;
    }
    if (
      position.tradeType == TradeType.SHORT &&
      position.entryPrice >= indexTokenPrice
    ) {
      isProfit = true;
    }

    uint256 pnl = 0;
    // if long & profit or short & loss => current price > entry price
    if (
      (position.tradeType == TradeType.LONG && isProfit) ||
      (position.tradeType == TradeType.SHORT && !isProfit)
    ) {
      pnl = position
        .size
        .getSize(indexTokenPrice - position.entryPrice)
        .getAmount(indexTokenPrice);
    }

    // if long & loss or short & profit => current price < entry price
    if (
      (position.tradeType == TradeType.LONG && !isProfit) ||
      (position.tradeType == TradeType.SHORT && isProfit)
    ) {
      pnl = position
        .size
        .getSize(position.entryPrice - indexTokenPrice)
        .getAmount(indexTokenPrice);
    }

    if (_withFee) {
      // in loss, add the fee to pnl
      if (!isProfit) {
        pnl += position.incurredFee;
      }

      // in profit, if the pnl > fee
      if (isProfit && pnl > position.incurredFee) {
        pnl -= position.incurredFee;
      }

      // in profit, if the pnl < fee
      if (isProfit && pnl < position.incurredFee) {
        pnl = position.incurredFee - pnl;
        isProfit = false;
      }
    }
    return (isProfit, pnl);
  }

  function _getLatestBorrowRate(address _indexToken, TradeType _tradeType)
    internal
    view
    returns (uint256)
  {
    uint256 borrowRate = borrowRates[_indexToken].borrowRate[_tradeType][
      borrowRates[_indexToken].borrowRateUpdatedTimestamp
    ];
    if (borrowRate == 0) {
      borrowRate = 1;
    }
    return borrowRate;
  }

  function _getUtilizationRate(address _token) internal view returns (uint256) {
    return
      reservedLiquidity[_token].getRatio(
        IERC20(_token).balanceOf(address(sapphirePool))
      );
  }

  function _canUpdateBorrowRate(address _token) internal view returns (bool) {
    return
      borrowRates[_token].borrowRateUpdatedTimestamp +
        borrowRates[_token].borrowRateIntervel >
      block.timestamp;
  }

  function updateBorrowFee(address _token) external {
    // ? seperate the borrow rate for long short?
    // check if the update timestamp has exceed limit
    require(_canUpdateBorrowRate(_token), "not ready to update borrow rate");
    // get the utilization rate
    uint256 utilizationRate = _getUtilizationRate(_token);
    // update the accumulative borrow rate, 0.001% of the utilization rate
    borrowRates[_token].borrowRate[TradeType.LONG][
      borrowRates[_token].borrowRateUpdatedTimestamp
    ] = utilizationRate.getPercentage(1e15);
  }

  function _debitBorrowFee(uint256 _tokenId) internal {
    // get position metadata
    SapphirePosition memory position = sapphireNFT.getPositionMetadata(
      _tokenId
    );
    uint256 fee = _calculateBorrowFee(_tokenId);
    // add the fee into incurred fee
    sapphireNFT.addIncurredFee(_tokenId, fee);
    sapphireNFT.updateLastBorrowRate(
      _tokenId,
      _getLatestBorrowRate(position.indexToken, position.tradeType)
    );
    emit DebitBorrowFee(_tokenId, fee);
  }

  function _calculateBorrowFee(uint256 tokenId) private view returns (uint256) {
    // get the position
    SapphirePosition memory position = sapphireNFT.getPositionMetadata(tokenId);
    // get the total borrow rate over the last position updated block and current block
    uint256 totalBorrowRate = (_getLatestBorrowRate(
      position.indexToken,
      position.tradeType
    ) - position.lastBorrowRate) * position.size;
    // calculate the fee
    uint256 fee = position.size.getPercentage(totalBorrowRate);
    return fee;
  }

  function _calculateOpenPositionFee(address _indexToken, uint256 _size)
    private
    view
    returns (uint256)
  {
    // todo add the spread fee here
    return _size.getPercentage(openPositionFeeBPS);
  }

  function _debitClosePositionFee(uint256 tokenId) internal {
    // calculate the fee
    uint256 fee = _calculateClosePositionFee(tokenId);
    // add the fee into incurred fee
    sapphireNFT.addIncurredFee(tokenId, fee);
    // emit event
    emit DebitClosePositionFee(tokenId, fee);
  }

  function _calculateClosePositionFee(uint256 tokenId)
    private
    view
    returns (uint256)
  {
    // get the position
    SapphirePosition memory position = sapphireNFT.getPositionMetadata(tokenId);
    return position.size.getPercentage(closePositionFeeBPS);
  }
}
