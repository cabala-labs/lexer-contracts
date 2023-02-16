// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract MockToken is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimal
  ) ERC20(_name, _symbol) {
    decimals_ = _decimal;
    allowedAddress[msg.sender] = true;
  }

  uint8 private decimals_;

  mapping(address => bool) allowedAddress;

  modifier onlyAllowed() {
    require(allowedAddress[msg.sender], "Not allowed");
    _;
  }

  function setAllowedAddress(address _address, bool _flag) external {
    allowedAddress[_address] = _flag;
  }

  function decimals() public view virtual override returns (uint8) {
    return decimals_;
  }

  function setDecimal(uint8 _decimal) public {
    decimals_ = _decimal;
  }

  function mint(address _to, uint256 _amount) public onlyAllowed {
    super._mint(_to, _amount);
  }

  function transfer(address to, uint256 amount)
    public
    override
    onlyAllowed
    returns (bool)
  {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public override onlyAllowed returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }
}
