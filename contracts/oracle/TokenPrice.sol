// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* TokenPrice.sol
This contract is used to feed, get and guard the price of a ERC20 token
*/

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../access/IAccessControl.sol";

import "hardhat/console.sol";

contract TokenPrice {
    IAccessControl public accessControl;

    bytes32 private constant TOKENPRICE_FEEDER = bytes32("TokenPrice_Feeder");
    bytes32 private constant TOKENPRICE_KEEPER = bytes32("TokenPrice_Keeper");
    // bytes32 private constant TOKENPRICE_GUARD = bytes32("TokenPrice_Guard");

    struct Price {
        uint256 timestamp;
        uint256 price;
    }

    struct Token {
        bool isTokenAvaliable;
        address chainlinkAddress;
        uint256 latestRound;
        mapping(uint256 => Price) prices;
    }

    event PriceSubmitted(address indexed token, uint256 roundId, uint256 price);

    mapping(address => Token) public tokens;
    bool spreadEnforced;

    constructor(address _accessControl) {
        accessControl = IAccessControl(_accessControl);
    }

    function decimals() external pure returns (uint256) {
        return 8;
    }

    // max, min
    function getPrice(address _token) external view returns (uint256, uint256) {
        // require(tokens[_token].isTokenAvaliable, "token_unavailable");

        // fetch the latest price from feeder
        uint256 feederPrice = tokens[_token].prices[tokens[_token].latestRound - 1].price;

        // fetch the latest price from chainlink
        // (, int256 uncastedChainlinkPrice, , , ) = AggregatorV3Interface(
        //     tokens[_token].chainlinkAddress
        // ).latestRoundData();

        // uint256 chainlinkPrice = uint256(uncastedChainlinkPrice);

        // compare and calculate the spread
        // uint256 difference = feederPrice > chainlinkPrice
        //     ? feederPrice - chainlinkPrice
        //     : chainlinkPrice - feederPrice;

        // check if
        // 1. there's spread, i.e. difference is larger than 2.5% of chainlink price, or
        // 2. spread is enforced
        // if (chainlinkPrice * 25 > difference * 1000 || spreadEnforced) {
        //     // return the price from chainlink with spread as max and min
        //     if (feederPrice > chainlinkPrice) {
        //         return ((chainlinkPrice * 25) / 1000, chainlinkPrice);
        //     } else {
        //         return (chainlinkPrice, (chainlinkPrice * 25) / 1000);
        //     }
        // }

        // return the price from feeder as both max and min if no spread
        return (feederPrice, feederPrice);
    }

    function setLatestPrice(address _token, uint256 _price) external {
        require(accessControl.hasRole(msg.sender, TOKENPRICE_FEEDER), "feeder_only");
        require(tokens[_token].isTokenAvaliable, "token_unavailable");
        require(_price > 0, "price_zero");
        tokens[_token].prices[tokens[_token].latestRound].price = _price;
        emit PriceSubmitted(_token, tokens[_token].latestRound, _price);
        tokens[_token].latestRound += 1;
    }

    function addToken(address _token) external {
        require(accessControl.hasRole(msg.sender, TOKENPRICE_KEEPER), "keeper_only");
        require(!tokens[_token].isTokenAvaliable, "token_already_added");
        tokens[_token].isTokenAvaliable = true;
    }

    function removeToken(address _token) external {
        require(accessControl.hasRole(msg.sender, TOKENPRICE_KEEPER), "keeper_only");
        require(tokens[_token].isTokenAvaliable, "token_unavailable");
        tokens[_token].isTokenAvaliable = false;
    }
}
