// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IPoolToken.sol";

contract PoolToken is IPoolToken, ERC20 {
  constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
  {}

  function mint(address _to, uint256 _amount) external {
    super._mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) external {
    super._burn(_from, _amount);
  }
}
