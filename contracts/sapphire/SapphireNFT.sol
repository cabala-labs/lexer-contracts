// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphireNFT.sol
This contract is used to manage the position of the user in Sapphire engine, and treat position as NFT
*/

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ICommon.sol";

contract SapphireNFT is ERC721Enumerable, ICommon {
  constructor() ERC721("SapphireNFT", "SAPPHIRE") {}

  mapping(uint256 => Position) private positions;

  function getPositonMetadata(uint256 _tokenId)
    external
    view
    returns (Position memory)
  {
    return positions[_tokenId];
  }

  function mint(address _to, Position memory _position)
    external
    returns (uint256)
  {
    uint256 tokenId = totalSupply();
    positions[tokenId] = _position;
    _safeMint(_to, tokenId);
    return tokenId;
  }

  function burn(uint256 _tokenId) external {
    _burn(_tokenId);
  }
}
