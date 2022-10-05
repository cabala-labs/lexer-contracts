// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* Referral.sol
This contract is used to 
*/

contract IReferral {
  struct ReferralSchema {
    address referer;
    uint256 referrerShare;
    uint256 referreeShare;
  }
}
