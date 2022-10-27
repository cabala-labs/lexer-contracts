// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* EmeraldPool.sol
This contract is used to
*/

import "../pool/BasePool.sol";

contract EmeraldPool is BasePool {
  // ---------- contract storage ----------

  // ---------- constructor ----------
  constructor(address _priceFeedAddress, address _atmAddress)
    BasePool("EmrPool", _atmAddress, _priceFeedAddress)
  {}

  // ---------- storage setters ----------

  // ---------- action functions ----------

  // ---------- view functions ----------

  // ---------- internal helpers ----------
  function _calStakeFee(address _tokenIn, uint256 _amountIn)
    internal
    view
    override
    returns (uint256)
  {
    return 0;
  }

  function _calUnstakeFee(address _tokenOut, uint256 _amountIn)
    internal
    view
    override
    returns (uint256)
  {
    return 0;
  }
}
