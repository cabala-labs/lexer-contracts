// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../nft/ISapphireNFT.sol";
import "./ISapphireTrade.sol";
import "./SapphireTradeViews.sol";

abstract contract SapphireTradeActions is SapphireTadeViews {
  ISapphireNFT internal sapphireNFT;

  function _debitClosingFee(uint256 tokenId) internal {
    // calculate the fee
    uint256 fee = _calculateClosingFee(tokenId);
    // add the fee into incurred fee
    sapphireNFT.addIncurredFee(tokenId, fee);
    // emit event
    emit DebitClosingFee(tokenId, fee);
  }
}
