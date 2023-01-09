// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "./IBaseTradeOrder.sol";

import "../token/TokenLibs.sol";
import "../atm/IATM.sol";
import "../trade/IBaseTrade.sol";
import "../ERC721T/ERC721T.sol";
import "../properties/FundWithdrawable.sol";
import "../oracle/ISimplePriceFeed.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract BaseTradeOrder is
  IBaseTradeOrder,
  ERC721T,
  FundWithdrawable,
  Ownable
{
  using TokenLibs for uint256;
  // ---------- contract storage ----------
  string public contractName;
  IATM atm;
  ISimplePriceFeed priceFeed;
  IBaseTrade trade;

  mapping(uint256 => OrderType) public orderTypes;
  mapping(uint256 => OpenOrder) public openOrders;
  mapping(uint256 => CloseOrder) public closeOrders;

  uint256 gas = 0.001 ether;

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
    Ownable()
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
  function createOpenOrder(
    Instruction _instruction,
    uint256 _orderPrice,
    uint256 _indexPair,
    IBaseTrade.TradeType _tradeType,
    uint256 _size,
    address _depositToken,
    uint256 _depositAmount,
    uint256 _totalDepositAmount
  ) external payable {
    require(msg.value == gas, "gas fee not met");
    payable(owner()).transfer(msg.value);

    //! accept only full deposit now
    require(_totalDepositAmount == _depositAmount, "under deposit");

    // receive deposit from user
    atm.transferFrom(_depositToken, msg.sender, address(this), _depositAmount);

    // create trade order
    OpenOrder memory newOpenOrder = OpenOrder({
      instruction: _instruction,
      tradeType: _tradeType,
      indexPair: _indexPair,
      orderPrice: _orderPrice,
      size: _size,
      depositToken: _depositToken,
      depositAmount: _depositAmount,
      totalDepositAmount: _totalDepositAmount
    });

    // mint a new position NFT to the user
    uint256 tokenId = totalMinted();
    orderTypes[tokenId] = OrderType.OPEN;
    openOrders[tokenId] = newOpenOrder;

    _mint(msg.sender, tokenId);

    emit OpenOrderCreated(
      msg.sender,
      tokenId,
      _instruction,
      _orderPrice,
      _indexPair,
      _tradeType,
      _size,
      _depositToken,
      _depositAmount,
      _totalDepositAmount
    );
  }

  function createCloseOrder(
    Instruction _instruction,
    uint256 _positionId,
    uint256 _orderPrice,
    address _withdrawToken,
    address _withdrawAddress
  ) external payable {
    require(msg.value == gas, "gas fee not met");
    payable(owner()).transfer(msg.value);
    // todo check if msg.sender is the owner/user of the position

    CloseOrder memory newCloseOrder = CloseOrder({
      instruction: _instruction,
      positionId: _positionId,
      orderPrice: _orderPrice,
      withdrawToken: _withdrawToken,
      withdrawAddress: _withdrawAddress
    });

    // mint a new position NFT to the user
    uint256 tokenId = totalMinted();
    orderTypes[tokenId] = OrderType.CLOSE;
    closeOrders[tokenId] = newCloseOrder;

    _mint(msg.sender, tokenId);

    emit CloseOrderCreated(
      msg.sender,
      tokenId,
      _instruction,
      _orderPrice,
      _positionId,
      _withdrawToken
    );
  }

  function executeOrder(uint256 _tokenId) external {
    // execute the order in trade contract
    OrderType orderType = orderTypes[_tokenId];

    if (orderType == OrderType.OPEN) {
      _executeOpenOrder(_tokenId);
    } else if (orderType == OrderType.CLOSE) {
      _executeCloseOrder(_tokenId);
    }
  }

  function updateOrderSize(uint256 _tokenId, uint256 _size) external {
    //todo check again the leverage margin
    // check if order is open order
    require(orderTypes[_tokenId] == OrderType.OPEN, "not open order");
    openOrders[_tokenId].size = _size;
  }

  function updateOrderDeposit(
    uint256 _tokenId,
    uint256 _updatedTotalDepositAmount,
    uint256 _updatedDepositAmount
  ) external {
    // check if order is open order
    require(orderTypes[_tokenId] == OrderType.OPEN, "not open order");

    OpenOrder memory openOrder = openOrders[_tokenId];

    if (openOrder.totalDepositAmount != _updatedTotalDepositAmount) {
      //todo check again the leverage margin
      openOrder.totalDepositAmount = _updatedTotalDepositAmount;
    }
    //! accept only full deposit now
    atm.transferFrom(
      openOrder.depositToken,
      ownerOf(_tokenId),
      address(this),
      _updatedTotalDepositAmount - openOrder.totalDepositAmount
    );
    return;

    if (_updatedDepositAmount == openOrder.depositAmount) return;

    // increase deposit
    if (_updatedDepositAmount > openOrder.depositAmount) {
      //todo check if the user is depositing more than he should
      // receive the extra deposit amount
      atm.transferFrom(
        openOrder.depositToken,
        ownerOf(_tokenId),
        address(this),
        _updatedDepositAmount - openOrder.depositAmount
      );
      return;
    }

    if (_updatedDepositAmount < openOrder.depositAmount) {
      //todo check the deposit ratio
      // give the user their deposit back
      atm.transferFrom(
        openOrder.depositToken,
        ownerOf(_tokenId),
        address(this),
        openOrder.depositAmount - _updatedDepositAmount
      );
    }
  }

  function cancelOrder(uint256 _tokenId) external {
    _closeOrder(_tokenId, false);
  }

  function setGas(uint256 _gas) external onlyOwner {
    gas = _gas;
  }

  // ---------- view functions ----------

  // ---------- internal functions ----------
  function _executeOpenOrder(uint256 _tokenId) internal {
    OpenOrder memory openOrder = openOrders[_tokenId];

    // check if the price now can execute the order
    require(_canExecuteOrder(_tokenId), "order entry price not met");

    // // transfer the rest of the deposit from the order owner
    // try
    //   atm.transferFrom(
    //     openOrder.depositToken,
    //     ownerOf(_tokenId),
    //     address(this),
    //     openOrder.totalDepositAmount - openOrder.depositAmount
    //   )
    // {
    //   openOrder.depositAmount +=
    //     openOrder.totalDepositAmount -
    //     openOrder.depositAmount;
    // } catch {
    //   // if cannot receive deposit, deduct 1% from deposit as penalty, send the rest back to the user
    //   _closeOrder(_tokenId, false);
    //   return;
    // }

    try
      trade.createPosition(
        ownerOf(_tokenId),
        openOrder.indexPair,
        openOrder.tradeType,
        openOrder.size,
        openOrder.depositToken,
        openOrder.depositAmount
      )
    {
      // close the order on successful execution
      _closeOrder(_tokenId, true);
    } catch {
      // if the position cannot be executed, send back the fund to user
      atm.transferFrom(
        openOrder.depositToken,
        address(this),
        ownerOf(_tokenId),
        openOrder.depositAmount
      );
      _closeOrder(_tokenId, false);
    }
  }

  function _executeCloseOrder(uint256 _tokenId) internal {
    CloseOrder memory closeOrder = closeOrders[_tokenId];

    try
      trade.closePosition(
        closeOrder.positionId,
        closeOrder.withdrawToken,
        closeOrder.withdrawAddress
      )
    {
      _closeOrder(_tokenId, true);
    } catch {
      _closeOrder(_tokenId, false);
    }
  }

  function _closeOrder(uint256 _tokenId, bool executed) internal {
    _burn(_tokenId);
    // delete the metadata
    OrderType orderType = orderTypes[_tokenId];
    if (orderType == OrderType.OPEN) {
      delete openOrders[_tokenId];
    } else if (orderType == OrderType.CLOSE) {
      delete closeOrders[_tokenId];
    }
    delete orderTypes[_tokenId];
    emit OrderClosed(_tokenId, executed);
  }

  function _canExecuteOrder(uint256 _tokenId) internal view returns (bool) {
    return true;
    OpenOrder memory openOrder = openOrders[_tokenId];

    // get the current price of the index pair
    uint256 currentPairPrice = priceFeed.getPairLatestPrice(
      openOrder.indexPair,
      openOrder.tradeType == IBaseTrade.TradeType.LONG
        ? ISimplePriceFeed.Spread.HIGH
        : ISimplePriceFeed.Spread.LOW
    );

    // return true for market order
    if (openOrder.instruction == Instruction.MARKET) {
      return true;
    }

    // for long order
    if (openOrder.tradeType == IBaseTrade.TradeType.LONG) {
      return currentPairPrice >= openOrder.orderPrice;
    }
    // for short order
    return currentPairPrice <= openOrder.orderPrice;
  }

  // ---------- overriding functions ----------
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal view override {
    return;
    if (from == address(0) || to == address(0)) return;

    OpenOrder memory openOrder = openOrders[tokenId];
    require(
      openOrder.totalDepositAmount == openOrder.depositAmount,
      "cannot transfer under deposit order"
    );
  }
}
