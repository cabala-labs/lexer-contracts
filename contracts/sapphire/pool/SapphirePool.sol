// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../oracle/ISimplePriceFeed.sol";

import "../../token/TokenLibs.sol";

import "./ISapphirePool.sol";
import "../token/ISapphireToken.sol";
import "../reward/ISapphireReward.sol";
import "../nft/ISapphireNFT.sol";
import "../swap/ISapphireSwap.sol";
import "../trade/ISapphireTrade.sol";

import "hardhat/console.sol";

contract SapphirePool is ISapphirePool {
  using TokenLibs for uint256;
  ISimplePriceFeed public priceFeed;

  address public sapphireTokenAddress;
  address public sapphireRewardAddress;
  address public sapphireNFTAddress;
  address public sapphireSwapAddress;
  address public sapphireTradeAddress;

  ISapphireToken public sapphireToken;
  ISapphireNFT public sapphireNFT;
  ISapphireSwap public sapphireSwap;
  ISapphireTrade public sapphireTrade;
  ISapphireReward public sapphireReward;

  mapping(address => TokenSetting) public tokenSettings;
  address[] public includedTokens;

  constructor(address _priceFeedAddress) {
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
  }

  function setContracts(
    address _sapphireTokenAddress,
    address _sapphireNFTAddress,
    address _sapphireSwapAddress,
    address _sapphireTradeAddress,
    address _sapphireRewardAddress
  ) external {
    sapphireToken = ISapphireToken(_sapphireTokenAddress);
    sapphireNFT = ISapphireNFT(_sapphireNFTAddress);
    sapphireSwap = ISapphireSwap(_sapphireSwapAddress);
    sapphireTrade = ISapphireTrade(_sapphireTradeAddress);
    sapphireReward = ISapphireReward(_sapphireRewardAddress);

    sapphireTokenAddress = _sapphireTokenAddress;
    sapphireNFTAddress = _sapphireNFTAddress;
    sapphireSwapAddress = _sapphireSwapAddress;
    sapphireTradeAddress = _sapphireTradeAddress;
    sapphireRewardAddress = _sapphireRewardAddress;
  }

  function getPoolAssetBalance(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256)
  {
    return _getPoolAssetBalance(s);
  }

  function getPoolTokenPrice(ISimplePriceFeed.Spread s)
    external
    view
    returns (uint256)
  {
    return _getPoolTokenPrice(s);
  }

  function stake(
    address _buyer,
    address _token,
    uint256 _amount,
    uint256 _minSapphireOut
  ) external {
    // get the price of the _token
    uint256 tokenPrice = priceFeed.getLatestPrice(
      _token,
      ISimplePriceFeed.Spread.LOW
    );
    // get the price of the sapphire token
    uint256 sapphireTokenPrice = _getPoolTokenPrice(
      ISimplePriceFeed.Spread.HIGH
    );
    // calculate the fee
    uint256 fee = _calculateStakeFee();
    // calculate the amount of sapphire token to mint
    uint256 sapphireTokenAmountOut = (_amount - fee)
      .getSize(tokenPrice)
      .getAmount(sapphireTokenPrice);
    // check against the _mintSapphireOut
    require(
      sapphireTokenAmountOut >= _minSapphireOut,
      "SapphirePool: insufficient_sapphire_out"
    );

    // take the _token from the _buyer
    IERC20(_token).transferFrom(_buyer, address(this), _amount);
    // collec the fee
    sapphireReward.collectFee(address(this), _token, fee, msg.sender);
    // mint the sapphire token to the _buyer
    sapphireToken.mint(_buyer, sapphireTokenAmountOut);
  }

  function unstake(
    address _seller,
    address _token,
    uint256 _amount,
    uint256 _mintTokenOut
  ) external {
    // get the price of the _token
    uint256 tokenPrice = priceFeed.getLatestPrice(
      _token,
      ISimplePriceFeed.Spread.HIGH
    );
    // get the price of the sapphire token
    uint256 sapphireTokenPrice = _getPoolTokenPrice(
      ISimplePriceFeed.Spread.LOW
    );
    // calculate the fee
    uint256 fee = _calculateUnstakeFee();
    // calculate the amount of _token to transfer
    uint256 tokenAmountOut = (_amount - fee).getSize(tokenPrice).getAmount(
      sapphireTokenPrice
    );
    // check against the _mintTokenOut
    require(
      tokenAmountOut >= _mintTokenOut,
      "SapphirePool: insufficient_token_out"
    );
    // burn the sapphire token from the buter
    sapphireToken.burn(_seller, _amount);
    // collect the fee
    sapphireReward.collectFee(address(this), _token, fee, msg.sender);
    // transfer the token to the _seller
    IERC20(_token).transfer(_seller, tokenAmountOut);
  }

  function addToken(address _tokenAddress) external {
    require(
      !tokenSettings[_tokenAddress].tokenActive,
      "SapphirePool: token_already_added"
    );
    tokenSettings[_tokenAddress].tokenActive = true;
    includedTokens.push(_tokenAddress);
  }

  function removeToken(address _tokenAddress) external {
    require(
      tokenSettings[_tokenAddress].tokenActive,
      "SapphirePool: token_not_added"
    );
    tokenSettings[_tokenAddress].tokenActive = false;
    for (uint256 i = 0; i < includedTokens.length; i++) {
      if (includedTokens[i] == _tokenAddress) {
        includedTokens[i] = includedTokens[includedTokens.length - 1];
        includedTokens.pop();
        break;
      }
    }
  }

  function _getPoolAssetBalance(ISimplePriceFeed.Spread s)
    internal
    view
    returns (uint256)
  {
    uint256 poolTotalBalance = 0;
    for (uint256 i = 0; i < includedTokens.length; i++) {
      // get the balance of the token in the pool
      uint256 tokenBalance = IERC20(includedTokens[i]).balanceOf(address(this));

      // normalize the token balance
      tokenBalance = tokenBalance.normalizeDecimal(includedTokens[i]);

      // get the USD value of the token
      uint256 tokenPrice = priceFeed.getLatestPrice(includedTokens[i], s);

      // add the USD value of the token to the total pool balance
      poolTotalBalance += tokenBalance.getSize(tokenPrice);
    }
    return poolTotalBalance;
  }

  function _getPoolTokenPrice(ISimplePriceFeed.Spread s)
    internal
    view
    returns (uint256)
  {
    // in case of no token has been minted
    // the price will always be 1 USD
    if (sapphireToken.totalSupply() == 0) return 1e18;
    return (_getPoolAssetBalance(s) * 1e18) / sapphireToken.totalSupply();
  }

  function _calculateStakeFee() internal view returns (uint256) {
    return 0;
  }

  function _calculateUnstakeFee() internal view returns (uint256) {
    return 0;
  }

  function withdraw(
    address _to,
    address _token,
    uint256 _amount
  ) external {
    console.log("bal", IERC20(_token).balanceOf(address(this)));
    IERC20(_token).transfer(_to, _amount);
  }
}
