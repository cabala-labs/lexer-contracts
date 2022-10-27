// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../trade/BaseTrade.sol";

contract SapphireTrade is BaseTrade {
  // ---------- contract storage ----------
  mapping(uint256 => address) public pairCollateral;
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

  function setPairCollateral(uint256 _pair, address _token) external {
    require(
      pairCollateral[_pair] == address(0),
      "SapTrade:pair_collateral_exists"
    );
    pairCollateral[_pair] = _token;
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
    return pairCollateral[_indexPair];
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
}
