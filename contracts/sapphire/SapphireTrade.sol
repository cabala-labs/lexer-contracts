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

  struct BorrowRate {
    mapping(TradeType => mapping(uint256 => uint256)) borrowRate;
    uint256 borrowRateUpdatedTimestamp;
    uint256 borrowRateIntervel;
  }
  mapping(address => BorrowRate) public borrowRates;

  mapping(address => uint256) public reservedLiquidity;

  uint256 public openPositionFeeBPS;

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
    uint256 _size,
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

    // calculate the fee for opening position
    uint256 openingFee = _calculateOpenPositionFee(_indexToken, _size);

    // mint a new positon NFT to the user
    uint256 tokenId = sapphireNFT.mint(
      _account,
      Position({
        indexToken: _indexToken,
        totalCollateralBalance: collateralBalance,
        size: _size,
        tradeType: _tradeType,
        entryPrice: indexTokenPrice.price[0],
        exitPrice: 0,
        incurredFee: openingFee,
        lastBorrowRate: _getLatestBorrowRate(_indexToken, _tradeType)
      })
    );
    // emit event
    emit PositionCreated(
      _account,
      tokenId,
      _indexToken,
      _tradeType,
      indexTokenPrice.price[0],
      _size,
      collateralBalance
    );
    emit DebitOpenPositionFee(tokenId, openingFee);
  }

  function closePosition(uint256 _tokenId, address _withdrawToken) external {
    //todo validaiton
    address account = sapphireNFT.ownerOf(_tokenId);
    Position memory position = sapphireNFT.getPositonMetadata(_tokenId);

    // get the price of the _withdrawToken
    ISimplePriceFeed.Price memory withdrawTokenPrice = priceFeed.getLatestPrice(
      _withdrawToken
    );

    // get the price of the index token
    ISimplePriceFeed.Price memory indexTokenPrice = priceFeed.getLatestPrice(
      position.indexToken
    );
    uint256 withdrawAmount = (position.totalCollateralBalance * 10**18) /
      indexTokenPrice.price[0];
    // debit the fee for closing position
    // debit the fee for borrowing
    _debitBorrowFee(_tokenId);
    // calculate the withdraw amount with pnl
    // collect the fee
    // send the withdraw amount minus fee to user
    IERC20(_withdrawToken).transfer(account, withdrawAmount);
    // burn the position NFT
    sapphireNFT.burn(_tokenId);

    // emit event
    emit PositionClosed(account, _tokenId, indexTokenPrice.price[0]);
  }

  function _getLatestBorrowRate(address _indexToken, TradeType _tradeType)
    internal
    view
    returns (uint256)
  {
    uint256 borrowRate = borrowRates[_indexToken].borrowRate[_tradeType][
      borrowRates[_indexToken].borrowRateUpdatedTimestamp
    ];
    if (borrowRate == 0) {
      borrowRate = 1;
    }
    return borrowRate;
  }

  function _getUtilizationRate(address _token) internal view returns (uint256) {
    return
      (reservedLiquidity[_token] * 10 * 18) /
      IERC20(_token).balanceOf(address(sapphirePool));
  }

  function _canUpdateBorrowRate(address _token) internal view returns (bool) {
    return
      borrowRates[_token].borrowRateUpdatedTimestamp +
        borrowRates[_token].borrowRateIntervel >
      block.timestamp;
  }

  function updateBorrowFee(address _token) external {
    // ? seperate the borrow rate for long short?
    // check if the update timestamp has exceed limit
    require(_canUpdateBorrowRate(_token), "not ready to update borrow rate");
    // get the utilization rate
    uint256 utilizationRate = _getUtilizationRate(_token);
    // update the accumulative borrow rate, 0.001% of the utilization rate
    borrowRates[_token].borrowRate[TradeType.Long][
      borrowRates[_token].borrowRateUpdatedTimestamp
    ] = utilizationRate / 100000;
  }

  function _debitBorrowFee(uint256 _tokenId) internal {
    // get position metadata
    Position memory position = sapphireNFT.getPositonMetadata(_tokenId);
    uint256 fee = _calculateBorrowFee(_tokenId);
    // add the fee into incurred fee
    sapphireNFT.addIncurredFee(_tokenId, fee);
    sapphireNFT.updateLastBorrowRate(
      _tokenId,
      _getLatestBorrowRate(position.indexToken, position.tradeType)
    );
    emit DebitBorrowFee(_tokenId, fee);
  }

  function _calculateBorrowFee(uint256 tokenId) private view returns (uint256) {
    // get the position
    Position memory position = sapphireNFT.getPositonMetadata(tokenId);
    // get the total borrow rate over the last position updated block and current block
    uint256 borrowRate = (_getLatestBorrowRate(
      position.indexToken,
      position.tradeType
    ) - position.lastBorrowRate) * position.size;
    // calculate the fee
    uint256 fee = (position.size * borrowRate) / 10**18;
    return fee;
  }

  function _calculateOpenPositionFee(address _indexToken, uint256 _size)
    private
    view
    returns (uint256)
  {
    // todo add the spread fee here
    return (_size * openPositionFeeBPS) / 10**18;
  }
}
