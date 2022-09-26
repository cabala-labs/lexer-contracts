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

  struct OpenPositon {
    uint256 tradeId;
    address account;
    address indexToken;
    uint256 totalCollateralBalance;
    uint256 size;
    TradeType tradeType;
    uint256 entryPrice;
  }
}
