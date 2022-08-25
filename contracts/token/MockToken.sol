// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        decimals_ = _decimal;
    }

    uint8 private decimals_;

    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }

    function setDecimal(uint8 _decimal) public {
        decimals_ = _decimal;
    }

    function mint(address _to, uint256 _amount) public {
        super._mint(_to, _amount);
    }
}
