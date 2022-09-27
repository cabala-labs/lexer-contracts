// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "./ISapphirePool.sol";
import "./ISapphireTrade.sol";
import "./SapphireNFT.sol";
import "../oracle/ISimplePriceFeed.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract SapphireTrade is ISapphireTrade {
  ISapphirePool sapphirePool;
  SapphireNFT sapphireNFT;
  ISimplePriceFeed priceFeed;

  constructor(
    address _sapphirePoolAddress,
    address _sapphireNFTAddress,
    address _priceFeedAddress
  ) {
    sapphirePool = ISapphirePool(_sapphirePoolAddress);
    sapphireNFT = SapphireNFT(_sapphireNFTAddress);
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
  }

  function createPosition(
    address _account,
    address _indexToken,
    TradeType _tradeType,
    uint256 _positionSize,
    address _collateralToken,
    uint256 _collateralAmount
  ) external {
    //todo validaiton

    // get the price of the colleteral token
    ISimplePriceFeed.Price memory collateralTokenPrice = priceFeed
      .getLatestPrice(_collateralToken);
    uint256 collateralBalance = (_collateralAmount *
      collateralTokenPrice.price[0]) / 10**18;

    ISimplePriceFeed.Price memory indexTokenPrice = priceFeed.getLatestPrice(
      _indexToken
    );

    // receive collateral from user
    IERC20(_collateralToken).transferFrom(
      _account,
      address(this),
      _collateralAmount
    );
    //todo calculate the fee for opening position
    // mint a new positon NFT to the user
    uint256 tokenId = sapphireNFT.mint(
      _account,
      Position({
        indexToken: _indexToken,
        totalCollateralBalance: collateralBalance,
        size: _positionSize,
        tradeType: _tradeType,
        entryPrice: indexTokenPrice.price[0],
        exitPrice: 0,
        incurredFee: 0
      })
    );
    // emit event
    emit PositionCreated(
      _account,
      tokenId,
      _indexToken,
      _tradeType,
      indexTokenPrice.price[0],
      _positionSize,
      collateralBalance
    );
  }

  function closePosition(uint256 _positionId, address _withdrawToken) external {
    //todo validaiton
    // calculate the fee for closing position
    // calculate the withdraw amount with pnl and fee
    // burn the position NFT
    sapphireNFT.burn(_positionId);
    // send the withdraw amount to user

    // emit event
    emit PositionClosed(msg.sender, _positionId, 0);
  }
}
