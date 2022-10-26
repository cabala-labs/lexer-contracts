// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* SapphireReward.sol
This contract is used to
*/

import "../reward/BaseReward.sol";

contract SapphireReward is BaseReward {
  // ---------- custom datatypes ----------
  // ---------- contract storage ----------
  // ---------- constructor ----------
  constructor(address _atm, address _referral)
    BaseReward("SapReward", _atm, _referral)
  {}
  // ---------- storage setters ----------
  // ---------- action functions ----------
  // ---------- view functions ----------
  // ---------- internal helpers ----------
}
