// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../pool/IBasePool.sol";
import "./IATM.sol";

contract ATM is IATM {
  function transferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _amount
  ) external {
    // check if _from is lexer contract
    if (_from.code.length > 0) {
      return IBasePool(_from).withdrawFund(_token, _to, _amount);
    }
    ERC20(_token).transferFrom(_from, _to, _amount);
  }
}
