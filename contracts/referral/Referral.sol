// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* Referral.sol
This contract is used to 
*/

contract Referral {
  struct ReferralSchema {
    address referer;
    uint256 referrerShare;
    uint256 referreeShare;
  }

  mapping(address => string) public referrers;
  mapping(address => string) public referrees;
  mapping(string => ReferralSchema) public referralSchemas;

  constructor() {}

  function createReferralCode(string memory referralCode) external {
    require(
      referralSchemas[referralCode].referer == address(0),
      "referral: code_exists"
    );
    require(
      bytes(referrers[msg.sender]).length == 0,
      "referral: referrer_exists"
    );
    require(bytes(referralCode).length != 0, "referral: empty_code");
    referralSchemas[referralCode] = ReferralSchema({
      referer: msg.sender,
      referrerShare: 5e18,
      referreeShare: 5e18
    });
    referrers[msg.sender] = referralCode;
  }

  function addReferrer(string memory referralCode) external {
    // check if the referral code exists
    require(
      referralSchemas[referralCode].referer != address(0),
      "referral: code_not_exists"
    );
    // the referrer cannot be the same as the referree
    require(
      msg.sender != referralSchemas[referralCode].referer,
      "referral: same_referrer_referree"
    );
    referrees[msg.sender] = referralCode;
  }

  function getReferralSchema(address _account)
    external
    view
    returns (ReferralSchema memory)
  {
    string memory referralCode = referrees[_account];
    return referralSchemas[referralCode];
  }
}
