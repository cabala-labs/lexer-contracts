// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* LEX.sol
This contract is used to create the LEX token, the governing token of the LEX ecosystem.
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LEX is ERC20 {
    constructor() ERC20("LEX", "LEX") {}

    bytes32 private constant LEX_ADMIN = bytes32("LEX_Admin");

    function mint(address _to, uint256 _amount) external {
        super._mint(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        super._burn(_from, _amount);
    }
}
