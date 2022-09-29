// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./ICommon.sol";

interface ISapphireTrade is ICommon {
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
  event DebitClosePositionFee(uint256 indexed _tokenId, uint256 _fee);
  event DebitCollateralSwapFee(uint256 indexed _tokenId, uint256 _fee);
  event DebitBorrowFee(uint256 indexed _tokenId, uint256 _fee);
  event CollectIncurredFee(uint256 indexed _tokenId, uint256 _fee);
}
