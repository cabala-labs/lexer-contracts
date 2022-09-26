// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICommon.sol";

interface ISapphireTrade is ICommon {
  event PositionCreated(
    address indexed _address,
    uint256 _tradeId,
    address _indexToken,
    uint256 _totalCollateralBalance,
    uint256 _entryPrice,
    uint256 _size,
    TradeType _tradeType
  );

  event PositionClosed(
    address indexed _address,
    uint256 _tradeId,
    uint256 _exitPrice
  );

  function getAddressOpenPositions(address _address)
    external
    view
    returns (OpenPositon[] memory);

  function createPosition(
    address _collateralToken,
    uint256 _amountIn,
    address _indexToken,
    uint256 _positionSize,
    TradeType _tradeType
  ) external;

  function closePosition(
    address _collateralToken,
    address _indexToken,
    uint256 _positionId
  ) external;
}
