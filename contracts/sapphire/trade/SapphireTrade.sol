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
import "../swap/ISapphireSwap.sol";

contract SapphireTrade is ISapphireTrade {
  using TokenLibs for uint256;
  ISimplePriceFeed priceFeed;
  ISapphirePool sapphirePool;
  ISapphireSwap sapphireSwap;
  ISapphireReward sapphireReward;
  ISapphireNFT sapphireNFT;

  struct BorrowRate {
    mapping(TradeType => mapping(uint256 => uint256)) borrowRate;
    uint256 borrowRateUpdatedTimestamp;
    uint256 borrowRateIntervel;
  }
  mapping(address => BorrowRate) public borrowRates;

  mapping(address => uint256) public reservedLiquidity;

  uint256 public openPositionFeeBPS;
  uint256 public closePositionFeeBPS;

  address public shortToken;

  constructor(address _priceFeedAddress, address _sapphirePoolAddress) {
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
    sapphirePool = ISapphirePool(_sapphirePoolAddress);
  }

  function setContract() external {
    sapphireSwap = ISapphireSwap(sapphirePool.sapphireSwapAddress());
    sapphireReward = ISapphireReward(sapphirePool.sapphireRewardAddress());
    sapphireNFT = ISapphireNFT(sapphirePool.sapphireNFTAddress());
  }

  function setShortToken(address _shortToken) external {
    shortToken = _shortToken;
  }

  function createPosition(
    address _account,
    address _indexToken,
    TradeType _tradeType,
    uint256 _size,
    address _depositToken,
    uint256 _depositAmount
  ) external {
    // receive collateral from user
    IERC20(_depositToken).transferFrom(_account, address(this), _depositAmount);

    // init a new position
    SapphirePosition memory position = SapphirePosition({
      indexToken: _indexToken,
      totalCollateralBalance: 0,
      totalCollateralAmount: _depositAmount,
      size: _size,
      tradeType: _tradeType,
      entryPrice: priceFeed.getLatestPrice(
        _indexToken,
        _tradeType == TradeType.LONG
          ? ISimplePriceFeed.Spread.HIGH
          : ISimplePriceFeed.Spread.LOW
      ),
      exitPrice: 0,
      incurredFee: _calculateOpenPositionFee(_indexToken, _size),
      lastBorrowRate: _getLatestBorrowRate(_indexToken, _tradeType)
    });

    // emit debit open position fee event
    emit DebitOpenPositionFee(sapphireNFT.totalSupply(), position.incurredFee);

    // check if swap is required
    address collateralToken = _tradeType == TradeType.LONG
      ? _indexToken
      : shortToken;

    if (collateralToken != _depositToken) {
      // swap collateral token and calculate the fee of swap in collateral token
      (uint256 amountOut, uint256 swapFee) = sapphireSwap.getSwapInfo(
        _depositToken,
        collateralToken,
        _depositAmount,
        ISapphireSwap.FeeCollectIn.OUT
      );

      // swap to collateralToken
      // console.log("swap collateral token");
      // console.log(_depositToken, _depositAmount);
      // console.log(collateralToken, amountOut);
      IERC20(_depositToken).transfer(address(sapphirePool), _depositAmount);
      sapphirePool.withdraw(address(this), collateralToken, amountOut);

      _depositAmount = amountOut;

      // update the position and debit the swap fee
      position.totalCollateralAmount = _depositAmount;
      position.incurredFee = position.incurredFee + swapFee;
      emit DebitOpenPositionFee(sapphireNFT.totalSupply(), swapFee);
    }

    // take a snapshot of the amount of the collateral token
    position.totalCollateralBalance = _depositAmount
      .normalizeDecimal(collateralToken)
      .getSize(_tradeType == TradeType.LONG ? position.entryPrice : 1e18);

    // mint a new positon NFT to the user
    uint256 tokenId = sapphireNFT.mint(_account, position);

    // emit event
    emit PositionCreated(
      _account,
      tokenId,
      _indexToken,
      _tradeType,
      position.entryPrice,
      _size,
      position.totalCollateralBalance,
      _depositAmount
    );
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

    // calculate the withdraw amount with positionPnL in usd value
    (bool isProfit, uint256 positionPnL) = _calculatePositionPnL(
      _tokenId,
      true
    );

    // console.log(position.totalCollateralBalance, positionPnL);

    address defaultWithdrawToken = position.tradeType == TradeType.LONG
      ? position.indexToken
      : shortToken;

    // send the collateral & pnl to the user/pool
    uint256 pnlAmount = positionPnL
      .getAmount(position.tradeType == TradeType.LONG ? indexTokenPrice : 1e18)
      .toTokenDecimal(defaultWithdrawToken);
    uint256 feeAmount = position
      .incurredFee
      .getAmount(position.tradeType == TradeType.LONG ? indexTokenPrice : 1e18)
      .toTokenDecimal(defaultWithdrawToken);

    if (isProfit) {
      // send collateral to the user
      IERC20(defaultWithdrawToken).transfer(
        account,
        position.totalCollateralAmount
      );
      // send pnl - fee to the user
      sapphirePool.withdraw(
        account,
        defaultWithdrawToken,
        pnlAmount - feeAmount
      );
    } else {
      // send the loss to the pool
      IERC20(defaultWithdrawToken).transfer(address(sapphirePool), pnlAmount);
      // send the remaining amount, i.e. collateral - pnl - fee, to the user
      IERC20(defaultWithdrawToken).transfer(
        account,
        position.totalCollateralAmount - pnlAmount - feeAmount
      );
    }

    // burn the position NFT
    sapphireNFT.burn(_tokenId);

    // emit event
    emit PositionClosed(account, _tokenId, indexTokenPrice);

    // swap the asset if swap is needed
    if (_withdrawToken != defaultWithdrawToken) {
      sapphireSwap.swapToken(_withdrawToken, defaultWithdrawToken, positionPnL);
    }
  }

  // calculate the amount of the token to withdraw
  function _calculatePositionWithdrawBalance(uint256 _tokenId)
    internal
    view
    returns (uint256)
  {
    (bool isProfit, uint256 positionPnL) = _calculatePositionPnL(
      _tokenId,
      true
    );
    SapphirePosition memory position = sapphireNFT.getPositionMetadata(
      _tokenId
    );
    return
      isProfit
        ? position.totalCollateralBalance + positionPnL
        : position.totalCollateralBalance - positionPnL;
  }

  function calculatePositionPnL(uint256 _tokenId, bool _withFee)
    external
    view
    returns (bool, uint256)
  {
    return _calculatePositionPnL(_tokenId, _withFee);
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
      indexTokenPrice >= position.entryPrice
    ) {
      isProfit = true;
    }
    if (
      position.tradeType == TradeType.SHORT &&
      indexTokenPrice <= position.entryPrice
    ) {
      isProfit = true;
    }

    uint256 positionPnL = 0;
    // if long & profit or short & loss => current price > entry price
    if (
      (position.tradeType == TradeType.LONG && isProfit) ||
      (position.tradeType == TradeType.SHORT && !isProfit)
    ) {
      positionPnL = position.size.normalizeDecimal(position.indexToken).getSize(
          indexTokenPrice - position.entryPrice
        );
    }

    // if long & loss or short & profit => current price < entry price
    if (
      (position.tradeType == TradeType.LONG && !isProfit) ||
      (position.tradeType == TradeType.SHORT && isProfit)
    ) {
      positionPnL = position.size.normalizeDecimal(position.indexToken).getSize(
          position.entryPrice - indexTokenPrice
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
    return (isProfit, positionPnL);
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
