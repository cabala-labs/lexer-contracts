// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        decimal_ = _decimal;
    }

    uint8 private decimal_;

    function decimals() public view override returns (uint8) {
        return decimal_;
    }

    function setDecimal(uint8 _decimal) public {
        decimal_ = _decimal;
    }

    function mint(address _to, uint256 _amount) public {
        super._mint(_to, _amount);
    }
}
