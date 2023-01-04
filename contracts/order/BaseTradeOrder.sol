// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IBaseTradeOrder.sol";

import "../token/TokenLibs.sol";
import "../atm/IATM.sol";
import "../trade/IBaseTrade.sol";
import "../ERC721T/ERC721T.sol";
import "../properties/FundWithdrawable.sol";
import "../oracle/ISimplePriceFeed.sol";

abstract contract BaseTradeOrder is IBaseTradeOrder, ERC721T, FundWithdrawable {
  using TokenLibs for uint256;
  // ---------- contract storage ----------
  string public contractName;
  IATM atm;
  ISimplePriceFeed priceFeed;
  IBaseTrade trade;
  mapping(uint256 => TradeOrder) internal tradeOrders;

  // ---------- constructor ----------
  constructor(
    string memory _contractName,
    address _atmAddress,
    address _priceFeedAddress
  )
    ERC721T(
      string.concat(_contractName, "_Order"),
      string.concat(_contractName, "_ORD")
    )
  {
    contractName = _contractName;
    atm = IATM(_atmAddress);
    priceFeed = ISimplePriceFeed(_priceFeedAddress);
  }

  // ---------- storage setters ----------
  function setTrade(address _tradeAddress) external {
    require(
      address(trade) == address(0),
      string.concat(contractName, ":trade_addr_exists")
    );
    trade = IBaseTrade(_tradeAddress);
  }

  // ---------- action functions ----------
  function createOrder(
    OrderType _orderType,
    uint256 _orderEntryPrice,
    uint256 _indexPair,
    IBaseTrade.TradeType _tradeType,
    uint256 _size,
    address _depositToken,
    uint256 _depositAmount,
    uint256 _totalDepositAmount
  ) external {
    //! accept only full deposit now
    require(_totalDepositAmount == _depositAmount, "under deposit");

    // receive deposit from user
    atm.transferFrom(_depositToken, msg.sender, address(this), _depositAmount);

    // create trade order
    TradeOrder memory newTradeOrder = TradeOrder({
      orderType: _orderType,
      orderEntryPrice: _orderEntryPrice,
      indexPair: _indexPair,
      tradeType: _tradeType,
      size: _size,
      depositToken: _depositToken,
      depositAmount: _depositAmount,
      totalDepositAmount: _totalDepositAmount
    });

    // mint a new position NFT to the user
    _mint(msg.sender, newTradeOrder);

    emit TradeOrderCreated(
      msg.sender,
      totalMinted() - 1,
      _orderType,
      _orderEntryPrice,
      _indexPair,
      _tradeType,
      _size,
      _depositToken,
      _depositAmount,
      _totalDepositAmount
    );
  }

  function executeOrder(uint256 _tokenId) external {
    // execute the order in trade contract
    // get the order
    TradeOrder memory traderOrder = tradeOrders[_tokenId];

    // check if the price now can execute the order
    require(_canExecuteOrder(_tokenId), "order entry price not met");

    // transfer the rest of the deposit from the order owner
    try
      atm.transferFrom(
        traderOrder.depositToken,
        ownerOf(_tokenId),
        address(this),
        traderOrder.totalDepositAmount - traderOrder.depositAmount
      )
    {
      traderOrder.depositAmount +=
        traderOrder.totalDepositAmount -
        traderOrder.depositAmount;
    } catch {
      // if cannot receive deposit, deduct 1% from deposit as penalty, send the rest back to the user
      _closeOrder(_tokenId, false);
      return;
    }

    try
      trade.createPosition(
        ownerOf(_tokenId),
        traderOrder.indexPair,
        traderOrder.tradeType,
        traderOrder.size,
        traderOrder.depositToken,
        traderOrder.depositAmount
      )
    {
      // close the order on successful execution
      _closeOrder(_tokenId, true);
    } catch {
      // if the position cannot be executed, send back the fund to user
      atm.transferFrom(
        traderOrder.depositToken,
        address(this),
        ownerOf(_tokenId),
        traderOrder.depositAmount
      );
      _closeOrder(_tokenId, false);
    }
  }

  function updateOrderSize(uint256 _tokenId, uint256 _size) external {
    //todo check again the leverage margin
    tradeOrders[_tokenId].size = _size;
  }

  function updateOrderDeposit(
    uint256 _tokenId,
    uint256 _updatedTotalDepositAmount,
    uint256 _updatedDepositAmount
  ) external {
    TradeOrder memory tradeOrder = tradeOrders[_tokenId];
    if (tradeOrder.totalDepositAmount != _updatedTotalDepositAmount) {
      //todo check again the leverage margin
      tradeOrder.totalDepositAmount = _updatedTotalDepositAmount;
    }
    //! accept only full deposit now
    atm.transferFrom(
      tradeOrder.depositToken,
      ownerOf(_tokenId),
      address(this),
      _updatedTotalDepositAmount - tradeOrder.totalDepositAmount
    );
    return;

    if (_updatedDepositAmount == tradeOrder.depositAmount) return;

    // increase deposit
    if (_updatedDepositAmount > tradeOrder.depositAmount) {
      //todo check if the user is depositing more than he should
      // receive the extra deposit amount
      atm.transferFrom(
        tradeOrder.depositToken,
        ownerOf(_tokenId),
        address(this),
        _updatedDepositAmount - tradeOrder.depositAmount
      );
      return;
    }

    if (_updatedDepositAmount < tradeOrder.depositAmount) {
      //todo check the deposit ratio
      // give the user their deposit back
      atm.transferFrom(
        tradeOrder.depositToken,
        ownerOf(_tokenId),
        address(this),
        tradeOrder.depositAmount - _updatedDepositAmount
      );
    }
  }

  function cancelOrder(uint256 _tokenId) external {
    _closeOrder(_tokenId, false);
  }

  // ---------- view functions ----------
  function getOrderMetadata(uint256 _tokenId)
    external
    view
    returns (TradeOrder memory)
  {
    return tradeOrders[_tokenId];
  }

  // ---------- internal functions ----------
  function _closeOrder(uint256 _tokenId, bool executed) internal {
    _burn(_tokenId);
    delete tradeOrders[_tokenId];
    emit TradeOrderClosed(_tokenId, executed);
  }

  function _canExecuteOrder(uint256 _tokenId) internal view returns (bool) {
    TradeOrder memory traderOrder = tradeOrders[_tokenId];

    // get the current price of the index pair
    uint256 currentPairPrice = priceFeed.getPairLatestPrice(
      traderOrder.indexPair,
      traderOrder.tradeType == IBaseTrade.TradeType.LONG
        ? ISimplePriceFeed.Spread.HIGH
        : ISimplePriceFeed.Spread.LOW
    );

    // return true for market order
    if (traderOrder.orderType == OrderType.MARKET) {
      return true;
    }

    // for long order
    if (traderOrder.tradeType == IBaseTrade.TradeType.LONG) {
      return currentPairPrice >= traderOrder.orderEntryPrice;
    }
    // for short order
    return currentPairPrice <= traderOrder.orderEntryPrice;
  }

  // ---------- overriding functions ----------
  function _mint(address _to, TradeOrder memory _order) internal {
    uint256 tokenId = totalMinted();
    tradeOrders[tokenId] = _order;
    super._safeMint(_to, tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal view override {
    if (from == address(0) || to == address(0)) return;

    TradeOrder memory traderOrder = tradeOrders[tokenId];
    require(
      traderOrder.totalDepositAmount == traderOrder.depositAmount,
      "cannot transfer under deposit order"
    );
  }
}
