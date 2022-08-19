// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EUROC is ERC20 {
    constructor() ERC20("EUROC", "EUROC") {}

    function mint(address _to, uint256 _amount) public {
        super._mint(_to, _amount);
    }
}
