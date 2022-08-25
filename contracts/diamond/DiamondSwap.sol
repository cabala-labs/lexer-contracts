// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DiamondPool.sol";
import "../oracle/TokenPrice.sol";
import "../token/TokenLibs.sol";

import "hardhat/console.sol";

contract DiamondSwap {
    using TokenLibs for uint256;

    struct SwapOrder {
        address account;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bool completed;
    }

    event SwapExecuted();
    event SwapOrderSubmitted();

    mapping(uint256 => SwapOrder) public swapOrders;
    uint256 latestOrderId;
    address public diamondPoolAddress;
    TokenPrice public tokenPrice;

    constructor(address _diamondPoolAddress, address _tokenPriceAddress) {
        diamondPoolAddress = _diamondPoolAddress;
        tokenPrice = TokenPrice(_tokenPriceAddress);
    }

    function placeSwapOrder(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _minAmountOut
    ) public returns (bool) {
        if (_canExecuteSwap(_tokenIn, _amountIn, _tokenOut, _minAmountOut)) {
            return _executeSwap(msg.sender, _tokenIn, _amountIn, _tokenOut, _minAmountOut);
        }
        SwapOrder memory newOrder = SwapOrder({
            account: msg.sender,
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            amountIn: _amountIn,
            minAmountOut: _minAmountOut,
            completed: false
        });
        swapOrders[latestOrderId] = newOrder;
        latestOrderId++;
        emit SwapOrderSubmitted();
        return false;
    }

    function canExecuteSwapOrder(uint256 orderId) public view returns (bool) {
        SwapOrder memory order = swapOrders[orderId];
        return _canExecuteSwap(order.tokenIn, order.amountIn, order.tokenOut, order.minAmountOut);
    }

    function _canExecuteSwap(
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _minAmountOut
    ) internal view returns (bool) {
        if (ERC20(_tokenIn).balanceOf(msg.sender) < _amountIn) {
            return false;
        }
        if (ERC20(_tokenOut).balanceOf(diamondPoolAddress) < _minAmountOut) {
            return false;
        }
        // check if the price * amount of token in is greater than the min amount of token out
        (uint256 inMinPrice, ) = tokenPrice.getPrice(_tokenIn);
        (, uint256 outMaxPrice) = tokenPrice.getPrice(_tokenOut);

        // adjust the token amount to 18 decimal places
        uint256 _inSize = _amountIn.toDecimal(ERC20(_tokenIn).decimals(), 18).getSize(inMinPrice);
        uint256 _outSize = _minAmountOut.toDecimal(ERC20(_tokenOut).decimals(), 18).getSize(
            outMaxPrice
        );

        // value of asset in is not enough to swap the requested value of another asset
        if (_inSize < _outSize) {
            return false;
        }

        return true;
    }

    function _executeSwap(
        address _account,
        address _tokenIn,
        uint256 _amountIn,
        address _tokenOut,
        uint256 _minAmountOut
    ) internal returns (bool) {
        (uint256 inMinPrice, ) = tokenPrice.getPrice(_tokenIn);
        (, uint256 outMaxPrice) = tokenPrice.getPrice(_tokenOut);
        ERC20(_tokenIn).transferFrom(_account, diamondPoolAddress, _amountIn);
        uint256 _inSize = _amountIn.toDecimal(ERC20(_tokenIn).decimals(), 18).getSize(inMinPrice);
        uint256 _outSize = _minAmountOut.toDecimal(ERC20(_tokenOut).decimals(), 18).getSize(
            outMaxPrice
        );
        uint256 actualAmountOut = (_inSize * 10**18) / _outSize;
        actualAmountOut = actualAmountOut.toDecimal(18, ERC20(_tokenOut).decimals());

        require(actualAmountOut >= _minAmountOut, "order_not_fulfilled");
        DiamondPool(diamondPoolAddress).withdrawToken(_tokenOut, _account, actualAmountOut);
        emit SwapExecuted();
        return true;
    }

    function executeSwapOrder(uint256 orderId) public returns (bool) {
        SwapOrder memory order = swapOrders[orderId];
        require(canExecuteSwapOrder(orderId), "order_not_fulfilled");
        _executeSwap(
            order.account,
            order.tokenIn,
            order.amountIn,
            order.tokenOut,
            order.minAmountOut
        );
        order.completed = true;
        return true;
    }
}
