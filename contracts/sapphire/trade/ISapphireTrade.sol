// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

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
    uint256 _totalCollateralBalance
  );

  event PositionClosed(
    address indexed _address,
    uint256 _tokenId,
    uint256 _exitPrice
  );

  event DebitOpenPositionFee(uint256 indexed _tokenId, uint256 _fee); // include open and depth impact
  event DebitCollateralSwapFee(uint256 indexed _tokenId, uint256 _fee);
  event DebitIncreaseSizeFee(uint256 indexed _tokenId, uint256 _fee); // to prevent opening at small size and increase size during open
  event DebitBorrowFee(uint256 indexed _tokenId, uint256 _fee);
  event DebitWithdrawalSwapFee(uint256 indexed _tokenId, uint256 _fee);
  event DebitClosePositionFee(uint256 indexed _tokenId, uint256 _fee);

  event CollectIncurredFee(uint256 indexed _tokenId, uint256 _fee);
}
