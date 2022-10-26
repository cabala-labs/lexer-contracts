// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* TokenLibs.sol
This contract is used to provide utils functions for ERC20 tokens
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

library TokenLibs {
  // normalize the token amount to 18 decimals
  function normalizeDecimal(uint256 _amount, address _tokenAddress)
    public
    view
    returns (uint256)
  {
    uint256 decimals = ERC20(_tokenAddress).decimals();
    if (decimals == 18) {
      return _amount;
    } else if (decimals > 18) {
      return _amount / (10**(decimals - 18));
    } else {
      return _amount * (10**(18 - decimals));
    }
  }

  // toTokenDecimal is used to convert the amount in 18 decimals to the token decimal
  function toTokenDecimal(uint256 _amount, address _tokenAddress)
    public
    view
    returns (uint256)
  {
    uint256 decimals = ERC20(_tokenAddress).decimals();
    if (decimals == 18) {
      return _amount;
    } else if (decimals > 18) {
      return _amount * (10**(decimals - 18));
    } else {
      return _amount / (10**(18 - decimals));
    }
  }

  // get the amount of the percentage of the total amount, the percentage is in 10 ** 18
  function getPercentage(uint256 _amount, uint256 _percentage)
    public
    pure
    returns (uint256)
  {
    return (_amount * _percentage) / 1e18;
  }

  // get the size of amount * price
  function getSize(uint256 _amount, uint256 _price)
    public
    pure
    returns (uint256)
  {
    return (_amount * _price) / 1e18;
  }

  function getAmount(uint256 _size, uint256 _price)
    public
    pure
    returns (uint256)
  {
    return (_size * 1e18) / _price;
  }

  function getRatio(uint256 nominator, uint256 denominator)
    public
    pure
    returns (uint256)
  {
    // 1% = 1e18, 100% = 1e20
    return (nominator * 1e20) / denominator;
  }
}
