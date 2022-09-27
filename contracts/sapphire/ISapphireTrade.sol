// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICommon.sol";

interface ISapphireTrade is ICommon {
  event PositionCreated(
    address indexed _address,
    uint256 _tradeId,
    address _indexToken,
    TradeType _tradeType,
    uint256 _entryPrice,
    uint256 _size,
    uint256 _totalCollateralBalance
  );

  event PositionClosed(
    address indexed _address,
    uint256 _tradeId,
    uint256 _exitPrice
  );
}
