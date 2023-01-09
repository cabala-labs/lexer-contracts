// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../trade/IBaseTrade.sol";

interface IBaseTradeOrder {
  // ---------- custom datatypes ----------
  enum OrderType {
    OPEN,
    CLOSE
  }

  enum Instruction {
    LIMIT,
    MARKET
  }

  struct OpenOrder {
    Instruction instruction;
    IBaseTrade.TradeType tradeType;
    uint256 indexPair;
    uint256 orderPrice;
    uint256 size;
    address depositToken;
    uint256 depositAmount;
    uint256 totalDepositAmount;
  }

  struct CloseOrder {
    Instruction instruction;
    uint256 positionId;
    uint256 orderPrice;
    address withdrawToken;
    address withdrawAddress;
  }

  // ---------- events ----------
  event OpenOrderCreated(
    address indexed account,
    uint256 tokenId,
    Instruction instruction,
    uint256 orderEntryPrice,
    uint256 indexPair,
    IBaseTrade.TradeType tradeType,
    uint256 size,
    address depositToken,
    uint256 depositAmount,
    uint256 totalDepositAmount
  );

  event CloseOrderCreated(
    address indexed account,
    uint256 tokenId,
    Instruction instruction,
    uint256 orderPrice,
    uint256 positionId,
    address withdrawToken
  );

  event OrderClosed(uint256 tokenId, bool executed);

  // ---------- action functions ----------
  function createOpenOrder(
    Instruction _instruction,
    uint256 _orderEntryPrice,
    uint256 _indexPair,
    IBaseTrade.TradeType _tradeType,
    uint256 _size,
    address _depositToken,
    uint256 _depositAmount,
    uint256 _collateralAmount
  ) external payable;

  function createCloseOrder(
    Instruction _instruction,
    uint256 _positionId,
    uint256 _orderExitPrice,
    address _withdrawToken,
    address _withdrawAddress
  ) external payable;

  function executeOrder(uint256 _tokenId) external;

  function updateOrderSize(uint256 _tokenId, uint256 _size) external;

  function updateOrderDeposit(
    uint256 _tokenId,
    uint256 _updatedTotalDepositAmount,
    uint256 _updatedDepositAmount
  ) external;

  function cancelOrder(uint256 _tokenId) external;
}
