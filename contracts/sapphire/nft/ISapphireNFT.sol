// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "../../ERC721T/IERC721T.sol";
import "../trade/ISapphireTrade.sol";

interface ISapphireNFT is IERC721T {
  function mint(address _to, ISapphireTrade.SapphirePosition memory _position)
    external
    returns (uint256);

  function burn(uint256 _tokenId) external;

  function getPositionMetadata(uint256 _tokenId)
    external
    view
    returns (ISapphireTrade.SapphirePosition memory);

  function addIncurredFee(uint256 _tokenId, uint256 _fee) external;

  function updateLastBorrowRate(uint256 _tokenId, uint256 _rate) external;
}
