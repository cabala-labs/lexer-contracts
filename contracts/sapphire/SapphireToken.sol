// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* SapphireToken.sol
This contract is used to
*/

import "../token/PoolToken.sol";

contract SapphireToken is PoolToken {
  // ---------- custom datatypes ----------
  // ---------- contract storage ----------
  // ---------- constructor ----------
  constructor() PoolToken("Sapphire", "SAP") {}
  // ---------- storage setters ----------
  // ---------- action functions ----------
  // ---------- view functions ----------
  // ---------- internal helpers ----------
}
