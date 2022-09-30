// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphireNFT.sol
This contract is used to manage the position of the user in Sapphire engine, and treat position as NFT
*/

import "../ERC721T/ERC721T.sol";
import "./ICommon.sol";

contract SapphireNFT is ERC721T, ICommon {
  constructor() ERC721T("SapphireNFT", "SAPPHIRE") {}

  mapping(uint256 => Position) private positions;

  address[] public lexerContracts;

  function getPositionMetadata(uint256 _tokenId)
    external
    view
    returns (Position memory)
  {
    return positions[_tokenId];
  }

  function addIncurredFee(uint256 _tokenId, uint256 _fee) external {
    positions[_tokenId].incurredFee += _fee;
  }

  function updateLastBorrowRate(uint256 _tokenId, uint256 _borrowRate)
    external
  {
    positions[_tokenId].lastBorrowRate = _borrowRate;
  }

  function adjustSize(uint256 _tokenId, uint256 _size) external {
    positions[_tokenId].size = _size;
  }

  function adjustCollateralBalance(uint256 _tokenId, uint256 _balance)
    external
  {
    positions[_tokenId].totalCollateralBalance = _balance;
  }

  function mint(address _to, Position memory _position)
    external
    returns (uint256)
  {
    uint256 tokenId = totalMinted();
    positions[tokenId] = _position;
    _safeMint(_to, tokenId);
    return tokenId;
  }

  function burn(uint256 _tokenId) external {
    _burn(_tokenId);
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    override
    returns (bool)
  {
    // check if the spender is lexer contract
    for (uint256 i = 0; i < lexerContracts.length; i++) {
      if (lexerContracts[i] == spender) {
        return true;
      }
    }
    return super._isApprovedOrOwner(spender, tokenId);
  }

  function addLexerContract(address _contract) external {
    lexerContracts.push(_contract);
  }

  function removeLexerContract(address _contract) external {
    for (uint256 i = 0; i < lexerContracts.length; i++) {
      if (lexerContracts[i] == _contract) {
        lexerContracts[i] = lexerContracts[lexerContracts.length - 1];
        lexerContracts.pop();
        break;
      }
    }
  }
}
