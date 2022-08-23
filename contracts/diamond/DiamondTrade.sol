// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IDiamondPool.sol";
import "../oracle/TokenPrice.sol";

contract DiamondTrade {
    enum TradeType {
        Long,
        Short
    }

    struct OpenPositon {
        address account;
        address indexToken;
        uint256 totalCollateralBalance;
        uint256 size;
        TradeType tradeType;
        uint256 entryPrice;
    }

    mapping(address => OpenPositon[]) public _openPositions;

    uint256 public maxLeverageLevel;

    TokenPrice public tokenPrice;
    address public diamondPoolAddress;

    constructor(address _diamondPoolAddress, address _tokenPriceAddress) {
        diamondPoolAddress = _diamondPoolAddress;
        tokenPrice = TokenPrice(_tokenPriceAddress);
    }

    function setMaxLeverageLevel(uint256 _maxLeverageLevel) public {
        maxLeverageLevel = _maxLeverageLevel;
    }

    function createPostion(
        address _collateralToken,
        uint256 _amountIn,
        address _indexToken,
        uint256 _positionSize,
        TradeType _tradeType
    ) external {
        (, uint256 collateralMinPrice) = tokenPrice.getPrice(_collateralToken);

        uint256 collateralBalance = _amountIn * collateralMinPrice;

        (uint256 maxEntryPrice, uint256 minEntryPrice) = tokenPrice.getPrice(_indexToken);

        require(_positionSize != 0, "empty_position");
        require(collateralBalance < _positionSize, "at_least_1x_leverage");
        require(collateralBalance * maxLeverageLevel <= _positionSize, "over_max_leverage");

        OpenPositon memory newOpenPosition = OpenPositon({
            account: msg.sender,
            indexToken: _indexToken,
            totalCollateralBalance: collateralBalance,
            tradeType: _tradeType,
            size: _positionSize,
            entryPrice: _tradeType == TradeType.Long ? maxEntryPrice : minEntryPrice
        });
        _openPositions[msg.sender].push(newOpenPosition);
    }

    function closePosition(uint256 _positionId, address _withdrawToken) external {
        OpenPositon memory position = _openPositions[msg.sender][_positionId];
        require(position.account == msg.sender, "not_your_position");
        _withdrawPnL(position, _withdrawToken);
    }

    function liquidatePosition(uint256 _positionId, address _withdrawToken) external {
        OpenPositon memory position = _openPositions[msg.sender][_positionId];
        (, uint256 loss) = getPositionPnL(position);
        // losing over 95% of the collateral
        require(
            loss * 100 * 1e18 >= position.totalCollateralBalance * 95 * 1e18,
            "not_enough_loss"
        );
        _withdrawPnL(position, _withdrawToken);
    }

    function _withdrawPnL(OpenPositon memory position, address _withdrawToken) private {
        (uint256 profit, uint256 loss) = getPositionPnL(position);

        uint256 closingAmountUSD = position.totalCollateralBalance + profit - loss;
        (, uint256 minClosingPrice) = tokenPrice.getPrice(_withdrawToken);
        uint256 closingAmount = closingAmountUSD / minClosingPrice;

        ERC20(_withdrawToken).transferFrom(diamondPoolAddress, position.account, closingAmount);
    }

    // return (profit, loss)
    function getPositionPnL(OpenPositon memory position) public view returns (uint256, uint256) {
        (uint256 maxIndexPrice, uint256 minIndexPrice) = tokenPrice.getPrice(position.indexToken);
        uint256 indexPrice = position.tradeType == TradeType.Long ? minIndexPrice : maxIndexPrice;

        uint256 profit = 0;
        uint256 loss = 0;

        // long and earning
        if (position.tradeType == TradeType.Long && position.entryPrice <= indexPrice) {
            profit = position.size * (indexPrice - position.entryPrice);
        }

        // long and losing
        if (position.tradeType == TradeType.Long && position.entryPrice > indexPrice) {
            loss = position.size * (position.entryPrice - indexPrice);
        }

        // short and earning
        if (position.tradeType == TradeType.Short && position.entryPrice >= indexPrice) {
            profit = position.size * (position.entryPrice - indexPrice);
        }

        // short and losing
        if (position.tradeType == TradeType.Short && position.entryPrice < indexPrice) {
            loss = position.size * (indexPrice - position.entryPrice);
        }

        return (profit, loss);
    }

    // function depositPositionCollateral(
    //     address _account,
    //     uint256 _positionId,
    //     address _collateralToken,
    //     uint256 _amountIn
    // ) external {}

    // function withdrawPositionCollateral(
    //     address _account,
    //     uint256 _positionId,
    //     address _collateralToken,
    //     uint256 _amountIn
    // ) external {}

    // function adjustPostionSize(uint256 _positionId) external {}
}
