// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../trade/BaseTrade.sol";

contract SapphireTrade is BaseTrade {
  // ---------- contract storage ----------
  mapping(uint256 => address) public indexPairToToken;
  address shortToken;

  // ---------- constructor ----------
  constructor(address _atm, address _priceFeed)
    BaseTrade("SapTrade", _atm, _priceFeed)
  {}

  // ---------- storage setters ----------
  function setShortToken(address _shortToken) external {
    require(address(shortToken) == address(0), "SapTrade:short_token_exists");
    shortToken = _shortToken;
  }

  function mapIndexPairToToken(uint256 _pair, address _token) external {
    require(indexPairToToken[_pair] == address(0), "SapTrade:pair_mapped");
    indexPairToToken[_pair] = _token;
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
    if (_tradeType == TradeType.SHORT) {
      return shortToken;
    }
    return indexPairToToken[_indexPair];
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
    return indexPairToToken[_indexPair];
  }
}
