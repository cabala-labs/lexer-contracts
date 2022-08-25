// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* DiamondPool.sol
This contract is used to manage the asset in Diamond pool, which holds the top performance assets.
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Diamond.sol";
import "./DiamondSwap.sol";
import "../oracle/TokenPrice.sol";
import "../token/TokenLibs.sol";

contract DiamondPool {
    using TokenLibs for uint256;

    // enum AskingPrice {
    //     MAX,
    //     MIN
    // }

    Diamond public diamond;
    DiamondSwap public diamondSwap;
    TokenPrice public tokenPrice;

    address[] public includedTokens;
    mapping(address => uint256) public tokenBalances;
    mapping(address => uint256) public tokenTargetProportion;

    uint256 public PERCENTAGE_BASE = 1e18;
    uint256 public basicFeePercentage;
    uint256 public lowestFeePercentage;
    uint256 public highestFeePercentage;

    constructor(address _diamondAddress, address _tokenPriceAddress) {
        diamond = Diamond(_diamondAddress);
        tokenPrice = TokenPrice(_tokenPriceAddress);
    }

    function getPoolTotalBalance() public view returns (uint256) {
        uint256 poolTotalBalance = 0;
        for (uint256 i = 0; i < includedTokens.length; i++) {
            uint256 tokenBalance = tokenBalances[includedTokens[i]];
            tokenBalance = tokenBalance.toDecimal(ERC20(includedTokens[i]).decimals(), 18);
            (uint256 maxPrice, uint256 minPrice) = tokenPrice.getPrice(includedTokens[i]);
            uint256 price = maxPrice;
            // uint256 price = askingPrice == AskingPrice.MAX ? maxPrice : minPrice;
            price = price.toDecimal(8, 18);
            poolTotalBalance += tokenBalance * price;
        }
        return poolTotalBalance;
    }

    function getDiamondPrice() public view returns (uint256) {
        // empty vault, 1 diamond = $1 usd
        if (getPoolTotalBalance() == 0) {
            return 1 * 10**18;
        }

        uint256 poolTotalBalance = getPoolTotalBalance();
        uint256 diamondSupply = diamond.totalSupply();
        return poolTotalBalance / diamondSupply;
    }

    function isTokenIncluded(address _token) public view returns (bool) {
        for (uint256 i = 0; i < includedTokens.length; i++) {
            if (includedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function getTokenProportion(address _token) public view returns (uint256) {
        return tokenBalances[_token] / getPoolTotalBalance();
    }

    /**
     * @dev better or worse, change
     *? use max or min??
     */
    function getProportionImpactSingle(address _token, uint256 _amount)
        public
        view
        returns (bool, uint256)
    {
        require(isTokenIncluded(_token) || _token == address(0x0), "token_not_included");
        (, uint256 minPrice) = tokenPrice.getPrice(_token);

        // calculate the proportion change relative to the target
        uint256 currentTokenProportion = tokenBalances[_token] / getPoolTotalBalance();
        uint256 currentProportionDifferent = currentTokenProportion > tokenTargetProportion[_token]
            ? currentTokenProportion - tokenTargetProportion[_token]
            : tokenTargetProportion[_token] - currentTokenProportion;

        uint256 newTokenBalance = tokenBalances[_token] + (_amount * minPrice);
        uint256 newTokenProportion = newTokenBalance / (getPoolTotalBalance() + newTokenBalance);
        uint256 newProportionDifferent = newTokenProportion > tokenTargetProportion[_token]
            ? newTokenProportion - tokenTargetProportion[_token]
            : tokenTargetProportion[_token] - newTokenProportion;

        bool isChangePositive = newProportionDifferent < currentProportionDifferent;
        uint256 change = isChangePositive
            ? currentProportionDifferent - newProportionDifferent
            : newProportionDifferent - currentProportionDifferent;

        return (isChangePositive, change);
    }

    function getProportionImpactPair(
        address _tokenA,
        uint256 _amountA,
        address _tokenB,
        uint256 _amountB
    ) public view returns (bool, uint256) {}

    function buyDiamond(
        address _buyer,
        address _token,
        uint256 _amount // denoted in _token
    ) external payable {
        // either send ERC20 or native token
        require((_token != address(0)) != (msg.value != 0), "either_ERC20_or_native_token");

        // check if it is native token
        bool isNativeToken = _token == address(0);

        if (isNativeToken) {
            require(_amount == msg.value, "incorrect_amount");
        }

        if (!isNativeToken) {
            require(isTokenIncluded(_token), "token_not_included");
            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }

        // // check the proportion impact on the pool
        // (bool isChangePositive, uint256 change) = getProportionImpactSingle(_token, _amount);

        // collect fee based on the proportion change
        // uint256 feePercentage = isChangePositive
        //     ? basicFeePercentage * (1 - change)
        //     : basicFeePercentage * (1 + change);

        // adjust the fee to fit in range
        // feePercentage = feePercentage < lowestFeePercentage
        //     ? lowestFeePercentage
        //     : feePercentage > highestFeePercentage
        //     ? highestFeePercentage
        //     : feePercentage;

        // get the price of the _token
        (, uint256 minPrice) = tokenPrice.getPrice(_token);
        minPrice = minPrice.toDecimal(8, 18);

        uint256 diamondPrice = getDiamondPrice();
        console.log(diamondPrice);

        //todo this part has all messed up decimals, plz fix lol
        uint256 inSize = _amount.toDecimal(ERC20(_token).decimals(), 18) * minPrice;
        uint256 diamondToMint = inSize / diamondPrice;

        // calculate the fee
        // uint256 fee = (_amount * minPrice * feePercentage) / PERCENTAGE_BASE;

        // mint the corresponding token to the _buyer
        // diamond.mint(_buyer, _amount - fee);
        diamond.mint(_buyer, diamondToMint);
    }

    function sellDiamond(
        address _seller,
        address _token,
        uint256 _amount // denoted in diamond
    ) external {
        require(isTokenIncluded(_token), "token_not_included");
        // get the price of the _token
        (, uint256 maxPrice) = tokenPrice.getPrice(_token);
        uint256 withdrawAmount = _amount / maxPrice;
        diamond.burn(_seller, _amount);
        IERC20(_token).transferFrom(address(this), _seller, withdrawAmount);
    }

    function rebalancePool() external {}

    function withdrawToken(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        ERC20(_token).transfer(_to, _amount);
    }

    function includeToken(address token) external {
        require(!isTokenIncluded(token), "token_already_included");
        includedTokens.push(token);
        tokenBalances[token] = 0;
    }
}
