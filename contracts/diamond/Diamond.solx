// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Diamond is ERC20 {
    constructor() ERC20("Diamond", "DIAMOND") {}

    bytes32 private constant DIAMOND_ADMIN = bytes32("Diamond_Admin");

    function mint(address _to, uint256 _amount) external {
        super._mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        super._burn(_from, _amount);
    }
}
