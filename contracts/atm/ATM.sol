// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../properties/FundWithdrawable.sol";
import "./IATM.sol";
import "hardhat/console.sol";

contract ATM is IATM {
  mapping(address => bool) public fundManagers;

  function addFundManager(address _fundManager) external {
    fundManagers[_fundManager] = true;
  }

  function transferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _amount
  ) external {
    require(fundManagers[msg.sender], "ATM: not fund manager");
    // check if _from is lexer contract which manages the fund
    if (fundManagers[_from]) {
      return FundWithdrawable(_from).withdrawFund(_token, _to, _amount);
    }
    IERC20(_token).transferFrom(_from, _to, _amount);
  }
}
