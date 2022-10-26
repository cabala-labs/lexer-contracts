// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* EmeraldToken.sol
This contract is used to
*/

import "../token/PoolToken.sol";

contract EmeraldToken is PoolToken {
  // ---------- custom datatypes ----------
  // ---------- contract storage ----------
  // ---------- constructor ----------
  constructor() PoolToken("Lexer Emerald", "EMR") {}
  // ---------- storage setters ----------
  // ---------- action functions ----------
  // ---------- view functions ----------
  // ---------- internal helpers ----------
}
