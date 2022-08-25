// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* TokenLibs.sol
This contract is used to provide utils functions for ERC20 tokens
*/

library TokenLibs {
    function toDecimal(
        uint256 amount,
        uint256 baseDecimal,
        uint256 targetDecimal
    ) public pure returns (uint256) {
        if (baseDecimal == targetDecimal) {
            return amount;
        }

        if (baseDecimal > targetDecimal) {
            return amount / (10**(targetDecimal - baseDecimal));
        }

        if (baseDecimal < targetDecimal) {
            return amount * (10**(targetDecimal - baseDecimal));
        }

        return 0;
    }

    function getSize(uint256 amount, uint256 price) public pure returns (uint256) {
        return (amount * price) / 10**8;
    }
}
