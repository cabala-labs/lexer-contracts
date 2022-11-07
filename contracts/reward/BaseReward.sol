// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "../referral/IReferral.sol";
import "../atm/IATM.sol";
import "./IBaseReward.sol";
import "../token/IPoolToken.sol";
import "../pool/ISwappablePool.sol";
import "../properties/FundWithdrawable.sol";

abstract contract BaseReward is IBaseReward, FundWithdrawable {
  // ---------- contract storage ----------
  string public name;

  IATM public atm;
  IReferral public referral;

  IPoolToken public poolToken;
  ISwappablePool public swappablePool;

  mapping(address => uint256) creditedRewards;
  mapping(address => uint256) claimedRewards;
  uint256 rewardAccumulater;
  address public teamAddress;
  uint256 public teamShare;
  address public feeToken;

  // ---------- constructor ----------
  constructor(
    string memory _name,
    address _atm,
    address _referral
  ) {
    name = _name;
    atm = IATM(_atm);
    referral = IReferral(_referral);
  }

  // ---------- storage setters ----------
  function setPoolToken(address _poolToken) external {
    require(
      address(poolToken) == address(0),
      string.concat(name, ":token_addr_exists")
    );
    poolToken = IPoolToken(_poolToken);
  }

  function setSwappablePool(address _swappablePool) external {
    require(
      address(swappablePool) == address(0),
      string.concat(name, ":swappable_pool_addr_exists")
    );
    swappablePool = ISwappablePool(_swappablePool);
  }

  function setTeamAddress(address _teamAddress) external {
    teamAddress = _teamAddress;
  }

  function setTeamShare(uint256 _teamShare) external {
    teamShare = _teamShare;
  }

  function setFeeToken(address _feeToken) external {
    feeToken = _feeToken;
  }

  // ---------- action functions ----------
  function collectFee(
    address _from,
    address _token,
    uint256 _amount,
    address _feePayer
  ) external {
    // transfer the fee to this contract via atm
    atm.transferFrom(_token, _from, address(this), _amount);

    // swap the token into feeToken, without fee
    (uint256 amountOut, uint256 fee) = swappablePool.swapTokenWithoutFee(
      _token,
      feeToken,
      _amount
    );

    // credit to team
    uint256 teamCredits = (fee * teamShare) / 1e18;
    creditedRewards[teamAddress] += teamCredits;
    emit CreditTeamReward(teamCredits);

    // credit to referrer and referree
    // search if the _feePayer has a referrer
    IReferral.ReferralSchema memory referralSchema = referral.getReferralSchema(
      _feePayer
    );
    uint256 referrerCredits = 0;
    uint256 referreeCredits = 0;
    if (referralSchema.referer != address(0)) {
      referrerCredits = (fee * referralSchema.referrerShare) / 100;
      creditedRewards[referralSchema.referer] += referrerCredits;
      emit CreditRefererReward(referralSchema.referer, referrerCredits);

      referreeCredits = (fee * referralSchema.referreeShare) / 100;
      creditedRewards[_feePayer] += referreeCredits;
      emit CreditReferreeReward(_feePayer, referreeCredits);
    }

    // if there is zero staker, credit the whole to team
    if (poolToken.totalSupply() == 0) {
      creditedRewards[teamAddress] += fee - teamCredits;
      emit CreditTeamReward(fee - teamCredits);
      return;
    }

    // credit the stakers by adding into the rewardAccumulater
    rewardAccumulater += (fee * 1e18) / poolToken.totalSupply();
  }

  function creditReward(address _account) external {
    creditedRewards[_account] += _calUnclaimedReward(_account);
    claimedRewards[_account] = rewardAccumulater;
  }

  function claimReward(address _account) external {
    uint256 totalReward = creditedRewards[_account] +
      _calUnclaimedReward(_account);
    creditedRewards[_account] = 0;
    claimedRewards[_account] = rewardAccumulater;
    IERC20(feeToken).transfer(_account, totalReward);
  }

  // ---------- view functions ----------
  function getUnclaimedReward(address _account)
    external
    view
    override
    returns (uint256)
  {
    return creditedRewards[_account] + _calUnclaimedReward(_account);
  }

  // ---------- internal functions ----------
  function _calUnclaimedReward(address _account)
    internal
    view
    returns (uint256 _reward)
  {
    return
      (rewardAccumulater - claimedRewards[_account]) *
      poolToken.balanceOf(_account);
  }
}
