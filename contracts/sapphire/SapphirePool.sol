// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ISapphirePool.sol";
import "./SapphireToken.sol";
import "../oracle/ISimplePriceFeed.sol";
import "hardhat/console.sol";

contract SapphirePool is ISapphirePool {
  struct TokenSetting {
    bool tokenActive;
  }

  mapping(address => TokenSetting) public tokenSettings;
  address[] public includedTokens;
  SapphireToken sapphireToken;
  ISimplePriceFeed priceFeed;

  constructor(address _sapphireTokenAddress, address _priceFeedAddress) {
    sapphireToken = SapphireToken(_sapphireTokenAddress);
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
  }

  function addToken(address _tokenAddress) external {
    require(!tokenSettings[_tokenAddress].tokenActive, "Token already added");
    tokenSettings[_tokenAddress].tokenActive = true;
    includedTokens.push(_tokenAddress);
  }

  /// @notice get the pool asset balance in USD value
  /// @param s max/min if spread
  /// @return uint256 the pool asset balance in USD value, 10 ** 6
  function getPoolAssetBalance(Spread s) external view returns (uint256) {
    return _getPoolAssetBalance(s);
  }

  function getPoolTokenBalance() external view returns (uint256) {
    return _getPoolTokenBalance();
  }

  function getPoolTokenPrice(Spread s) external view returns (uint256) {
    return _getPoolTokenPrice(s);
  }

  function stake(
    address _buyer,
    address _token,
    uint256 _amount
  ) external {
    // get the price of the _token
    ISimplePriceFeed.Price memory tokenPrice = priceFeed.getLatestPrice(_token);
    // todo check if the price > min price
    // get the max price of the sapphire token
    uint256 sapphireTokenPrice = _getPoolTokenPrice(Spread.MAX);
    // calculate the amount of sapphire token to mint
    uint256 sapphireTokenAmount = (_amount * tokenPrice.price[1]) /
      sapphireTokenPrice;
    // take the _token from the _buyer
    IERC20(_token).transferFrom(_buyer, address(this), _amount);
    // mint the sapphire token to the _buyer
    sapphireToken.mint(_buyer, sapphireTokenAmount);
  }

  function unstake(
    address _seller,
    address _token,
    uint256 _amount
  ) external {
    // get the price of the _token
    ISimplePriceFeed.Price memory tokenPrice = priceFeed.getLatestPrice(_token);
    // todo check if the price < max price
    // get the min price of the sapphire token
    uint256 sapphireTokenPrice = _getPoolTokenPrice(Spread.MIN);
    // calculate the amount of _token to send to the _seller
    uint256 tokenAmount = ((_amount * sapphireTokenPrice) * 10**18) /
      tokenPrice.price[1];
    // burn the sapphire token from the _seller
    sapphireToken.burn(_seller, _amount);
    // send the _token to the _seller
    IERC20(_token).transfer(_seller, tokenAmount);
  }

  function _getPoolAssetBalance(Spread s) internal view returns (uint256) {
    uint256 poolTotalBalance = 0;
    for (uint256 i = 0; i < includedTokens.length; i++) {
      // get the balance of the token in the pool
      uint256 tokenBalance = IERC20(includedTokens[i]).balanceOf(address(this));

      // get the USD value of the token
      ISimplePriceFeed.Price memory tokenPrice = priceFeed.getLatestPrice(
        includedTokens[i]
      );

      // add the USD value of the token to the total pool balance
      poolTotalBalance += (tokenBalance * tokenPrice.price[0]) / 10**18;
    }
    return poolTotalBalance;
  }

  function _getPoolTokenBalance() internal view returns (uint256) {
    return sapphireToken.balanceOf(address(this));
  }

  function _getPoolTokenPrice(Spread s) internal view returns (uint256) {
    // in case of no token has been minted
    // the price will always be 1 USD
    if (_getPoolTokenBalance() == 0) return 10**18;
    return _getPoolAssetBalance(s) / _getPoolTokenBalance();
  }
}
