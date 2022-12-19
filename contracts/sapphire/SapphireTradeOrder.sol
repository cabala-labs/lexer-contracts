// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../order/BaseTradeOrder.sol";

import "../token/TokenLibs.sol";

contract SapphireTradeOrder is BaseTradeOrder {
  using TokenLibs for uint256;

  // ---------- constructor ----------
  constructor(address _atm, address _priceFeed)
    BaseTradeOrder("SapTradeOrder", _atm, _priceFeed)
  {}
}
