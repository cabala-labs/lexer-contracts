// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./ISapphireTrade.sol";
import "../nft/ISapphireNFT.sol";
import "../../token/TokenLibs.sol";

abstract contract SapphireTadeViews is ISapphireTrade {
  using TokenLibs for uint256;
  ISapphireNFT internal sapphireNFT;
  uint256 internal closingFeeBPS;
  uint256 internal openingFeeBPS;

  function _calculateOpeningFee(address _indexToken, uint256 _size)
    private
    view
    returns (uint256)
  {
    return 0;
  }

  function _calculateBorrowFee(uint256 tokenId) private view returns (uint256) {
    // get the position
    SapphirePosition memory position = sapphireNFT.getPositionMetadata(tokenId);
    // get the total borrow rate over the last position updated block and current block
    uint256 totalBorrowRate = (_getLatestBorrowRate(
      position.indexToken,
      position.tradeType
    ) - position.lastBorrowRate) * position.size;
    // calculate the fee
    uint256 fee = position.size.getPercentage(totalBorrowRate);
    return fee;
  }

  function _calculateClosingFee(uint256 tokenId)
    internal
    view
    returns (uint256)
  {
    return 0;
    // // get the position
    // SapphirePosition memory position = sapphireNFT.getPositionMetadata(tokenId);
    // return position.size.getPercentage(closingFeeBPS);
  }

  function _canLiquidate(uint256 _tokenId) internal view returns (bool) {
    // todo check if the position is liquidatable
    return true;
  }
}
