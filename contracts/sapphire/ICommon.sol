// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICommon {
  enum Spread {
    MAX,
    MIN
  }

  enum TradeType {
    Long,
    Short
  }

  struct Position {
    address indexToken;
    TradeType tradeType;
    uint256 entryPrice;
    uint256 size;
    uint256 totalCollateralBalance;
    uint256 exitPrice;
    uint256 incurredFee;
    uint256 lastBorrowRate;
  }
}
