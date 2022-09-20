// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface ICommon {
  enum TradeType {
    Long,
    Short
  }

  struct OpenPositon {
    address account;
    address indexToken;
    uint256 totalCollateralBalance;
    uint256 size;
    TradeType tradeType;
    uint256 entryPrice;
  }
}
