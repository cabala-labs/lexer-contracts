// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../trade/IBaseTrade.sol";

interface IBaseTradeOrder {
  // ---------- custom datatypes ----------
  enum OrderType {
    LIMIT,
    MARKET
  }

  struct TradeOrder {
    OrderType orderType;
    uint256 orderEntryPrice;
    uint256 indexPair;
    IBaseTrade.TradeType tradeType;
    uint256 size;
    address depositToken;
    uint256 depositAmount;
    uint256 totalDepositAmount;
  }

  // ---------- events ----------
  event TradeOrderCreated(
    address indexed account,
    uint256 tokenId,
    OrderType orderType,
    uint256 orderEntryPrice,
    uint256 indexPair,
    IBaseTrade.TradeType tradeType,
    uint256 size,
    address depositToken,
    uint256 depositAmount,
    uint256 totalDepositAmount
  );

  event TradeOrderClosed(uint256 tokenId, bool executed);

  // ---------- action functions ----------
  function createOrder(
    OrderType _orderType,
    uint256 _orderEntryPrice,
    uint256 _indexPair,
    IBaseTrade.TradeType _tradeType,
    uint256 _size,
    address _depositToken,
    uint256 _depositAmount,
    uint256 _collateralAmount
  ) external;

  function executeOrder(uint256 _tokenId) external;

  function updateOrderSize(uint256 _tokenId, uint256 _size) external;

  function updateOrderDeposit(
    uint256 _tokenId,
    uint256 _updatedTotalDepositAmount,
    uint256 _updatedDepositAmount
  ) external;

  function cancelOrder(uint256 _tokenId) external;
}
