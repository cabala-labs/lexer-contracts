// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../trade/BaseTrade.sol";

contract EmeraldTrade is BaseTrade {
  // ---------- contract storage ----------
  address public collateralToken;

  // ---------- constructor ----------
  constructor(address _atm, address _priceFeed)
    BaseTrade("EmrTrade", _atm, _priceFeed)
  {}

  // ---------- storage setters ----------
  function setCollateralToken(address _collateralToken) external {
    collateralToken = _collateralToken;
  }

  // ---------- action functions ----------

  // ---------- view functions ----------

  // ---------- internal helpers ----------
  function _getCollateralToken(uint256 _indexPair, TradeType _tradeType)
    internal
    view
    override
    returns (address)
  {
    return collateralToken;
  }

  function _calOpenPositionFee(uint256 _indexPair, uint256 _size)
    internal
    view
    override
    returns (uint256)
  {
    return 0;
  }

  function _debitClosePositionFee(uint256 _tokenId) internal override {
    uint256 fee = 0;
    emit DebitClosingFee(_tokenId, fee);
  }

  function _getTradingToken(uint256 _indexPair)
    internal
    view
    override
    returns (address)
  {
    return collateralToken;
  }
}
