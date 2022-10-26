// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* Referral.sol
This contract is used to 
*/

interface IReferral {
  struct ReferralSchema {
    address referer;
    uint256 referrerShare;
    uint256 referreeShare;
  }

  function getReferralSchema(address _account)
    external
    view
    returns (ReferralSchema memory);
}
