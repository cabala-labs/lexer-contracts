// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface ISapphireTrade {
  enum TradeType {
    LONG,
    SHORT
  }

  struct SapphirePosition {
    address indexToken;
    TradeType tradeType;
    uint256 entryPrice;
    uint256 size;
    uint256 totalCollateralBalance;
    uint256 totalCollateralAmount;
    uint256 exitPrice;
    uint256 incurredFee;
    uint256 lastBorrowRate;
  }

  event PositionCreated(
    address indexed _address,
    uint256 _tokenId,
    address _indexToken,
    TradeType _tradeType,
    uint256 _entryPrice,
    uint256 _size,
    uint256 _totalCollateralBalance,
    uint256 _totalCollateralAmount
  );

  event PositionClosed(
    address indexed _address,
    uint256 _tokenId,
    uint256 _exitPrice
  );

  event DebitOpenPositionFee(uint256 indexed _tokenId, uint256 _feeAmount); // include open and depth impact
  event DebitCollateralSwapFee(uint256 indexed _tokenId, uint256 _feeAmount);
  event DebitIncreaseSizeFee(uint256 indexed _tokenId, uint256 _feeAmount); // to prevent opening at small size and increase size during open
  event DebitBorrowFee(uint256 indexed _tokenId, uint256 _feeAmount);
  event DebitClosingFee(uint256 indexed _tokenId, uint256 _feeAmount);

  event CollectIncurredFee(uint256 indexed _tokenId, uint256 _feeAmount);
}
