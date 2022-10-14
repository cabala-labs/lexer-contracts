// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphireNFT.sol
This contract is used to collect fees for trades in Sapphire Engine and distribute the reward to stakers, referrer and team
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../pool/ISapphirePool.sol";
import "../token/ISapphireToken.sol";
import "../swap/ISapphireSwap.sol";
import "../../referral/Referral.sol";

contract SapphireReward {
  uint256 rewardAccumulater;
  mapping(address => uint256) creditedRewards;
  Referral public referral;

  ISapphirePool public sapphirePool;
  ISapphireToken public sapphireToken;
  ISapphireSwap public sapphireSwap;

  address public teamAddress;
  uint256 public teamShare;
  address public feeToken;

  event CreditRefererReward(address indexed referer, uint256 amount);
  event CreditReferreeReward(address indexed referree, uint256 amount);
  event CreditStakerReward(address indexed staker, uint256 amount);
  event CreditTeamReward(uint256 amount);
  event ClaimReward(address indexed user, uint256 amount);

  constructor(address _sapphirePoolAddress, address _referralAddress) {
    sapphirePool = ISapphirePool(_sapphirePoolAddress);
    referral = Referral(_referralAddress);
  }

  function setContract() external {
    sapphireToken = ISapphireToken(sapphirePool.sapphireTokenAddress());
    sapphireSwap = ISapphireSwap(sapphirePool.sapphireSwapAddress());
  }

  function setFeeToken(address _token) external {
    feeToken = _token;
  }

  function collectFee(
    address _from,
    address _tokenAddress,
    uint256 _tokenAmount,
    address _feePayer
  ) external {
    // transfer the fee to this contract
    IERC20(_tokenAddress).transferFrom(_from, address(this), _tokenAmount);

    // swap the token into USDC, without fee
    uint256 usdcAmount = sapphireSwap.swapTokenWithoutFee(
      _tokenAddress,
      feeToken,
      _tokenAmount
    );

    // credit to team
    uint256 teamCredits = (usdcAmount * 5) / 100;
    creditedRewards[teamAddress] += teamCredits;
    emit CreditTeamReward(teamCredits);

    // credit to referrer and referree
    // search if the _feePayer has a referrer
    Referral.ReferralSchema memory referralSchema = referral.getReferralSchema(
      _feePayer
    );
    uint256 referrerCredits = 0;
    uint256 referreeCredits = 0;
    if (referralSchema.referer != address(0)) {
      referrerCredits = (usdcAmount * referralSchema.referrerShare) / 100;
      creditedRewards[referralSchema.referer] += referrerCredits;
      emit CreditRefererReward(referralSchema.referer, referrerCredits);

      referreeCredits = (usdcAmount * referralSchema.referreeShare) / 100;
      creditedRewards[_feePayer] += referreeCredits;
      emit CreditReferreeReward(_feePayer, referreeCredits);
    }

    // if there is no staker to credit, credit to the team
    if (sapphireToken.totalSupply() == 0) {
      creditedRewards[teamAddress] += usdcAmount;
      emit CreditTeamReward(teamCredits);
      return;
    }

    // add the remaining USDC amount / sapphire token supply to the reward accumulater
    rewardAccumulater += (usdcAmount * 10**18) / sapphireToken.totalSupply();
  }

  function _calculateReward(address _from, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    // add the credited reward and the unclaimed reward
    uint256 unclaimedReward = (rewardAccumulater * _amount) / 10**18;
    uint256 totalReward = creditedRewards[_from] + unclaimedReward;
    return totalReward;
  }

  function creditReward(address _account) external {}

  function claimReward(address _account) external {
    uint256 reward = _calculateReward(
      _account,
      sapphireToken.balanceOf(_account)
    );
    sapphireToken.transfer(_account, reward);
    emit ClaimReward(_account, reward);
  }
}
