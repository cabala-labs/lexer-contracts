// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract FundWithdrawable {
  function withdrawFund(
    address _token,
    address _to,
    uint256 _amount
  ) external {
    IERC20(_token).transfer(_to, _amount);
  }
}
