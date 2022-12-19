// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IBaseTrade {
  // ---------- custom datatypes ----------
  enum TradeType {
    LONG,
    SHORT
  }

  struct BorrowRate {
    uint256 accumulator;
    uint256 borrowRateUpdatedTimestamp;
  }

  struct Position {
    uint256 indexPair;
    TradeType tradeType;
    uint256 entryPrice;
    uint256 size;
    uint256 totalCollateralBalance;
    uint256 totalCollateralAmount; //todo remove this
    uint256 exitPrice;
    uint256 incurredFee;
    uint256 lastBorrowRate;
  }

  // ---------- events ----------
  event PositionCreated(
    address indexed account,
    uint256 tokenId,
    uint256 indexPair,
    TradeType tradeType,
    uint256 entryPrice,
    uint256 size,
    uint256 totalCollateralBalance,
    uint256 totalCollateralAmount
  );
  event PositionPartiallyClosed(
    address indexed account,
    uint256 tokenId,
    uint256 exitSizeAmount,
    uint256 exitPrice
  );
  event PositionClosed(
    address indexed account,
    uint256 tokenId,
    uint256 exitPrice
  );
  event PositionLiquidated(uint256 tokenId);

  event DebitOpenPositionFee(uint256 indexed tokenId, uint256 feeAmount); // include open and depth impact
  event DebitCollateralSwapFee(uint256 indexed tokenId, uint256 feeAmount);
  event DebitIncreaseSizeFee(uint256 indexed tokenId, uint256 feeAmount); // to prevent opening at small size and increase size during open
  event DebitBorrowFee(uint256 indexed tokenId, uint256 feeAmount);
  event DebitClosingFee(uint256 indexed tokenId, uint256 feeAmount);

  event CollectIncurredFee(uint256 indexed tokenId, uint256 feeAmount);

  // ---------- action functions ----------
  function createPosition(
    address account,
    uint256 indexPair,
    TradeType tradeType,
    uint256 size,
    address depositToken,
    uint256 depositAmount
  ) external;

  function closePosition(
    uint256 tokenId,
    address withdrawToken,
    address withdrawAddress
  ) external;

  function liquidatePosition(uint256 tokenId) external;

  function updateBorrowFee(uint256 indexPair) external;

  function getPositionMetadata(uint256 tokenId)
    external
    view
    returns (Position memory);

  // ---------- view functions ----------
  function calPositionPnL(uint256 tokenId, bool withFee)
    external
    view
    returns (bool, uint256);

  function isPositionLiquidatable(uint256 tokenId) external view returns (bool);

  function getCollateralToken(uint256 _indexPair, TradeType _tradeType)
    external
    view
    returns (address);
}
