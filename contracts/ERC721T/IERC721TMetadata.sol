// SPDX-License-Identifier: MIT
// Base Contract for ERC721T Token Metadata
// Modified from OpenZeppelin IERC721Metadata.sol v4.4.1

pragma solidity ^0.8.13;

import "./IERC721T.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721TMetadata is IERC721T {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}
