// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/* SapphirePool.sol
This contract is used to manage the asset in Sapphire pool, which holds the assets trading in Sapphire engine.
*/

import "./ISapphirePool.sol";
import "./ISapphireTrade.sol";

contract SapphireTrade is ISapphireTrade {
  ISapphirePool sapphirePool;

  constructor(address _sapphirePoolAddress) {
    sapphirePool = ISapphirePool(_sapphirePoolAddress);
  }

  function getAddressOpenPositions(address _address)
    external
    view
    override
    returns (OpenPositon[] memory)
  {
    OpenPositon[] memory positions = new OpenPositon[](2);
    // push 2 dummy data into positions
    positions[0] = OpenPositon({
      tradeId: 1,
      account: _address,
      indexToken: address(0),
      totalCollateralBalance: 10**18,
      entryPrice: 10**18,
      size: 10**18,
      tradeType: TradeType.Long
    });
    positions[1] = OpenPositon({
      tradeId: 2,
      indexToken: address(0),
      account: _address,
      totalCollateralBalance: 10**18,
      entryPrice: 10**18,
      size: 10**18,
      tradeType: TradeType.Short
    });
    return positions;
  }

  function createPosition(
    address _collateralToken,
    uint256 _amountIn,
    address _indexToken,
    uint256 _positionSize,
    TradeType _tradeType
  ) external override {
    // TODO
    emit PositionCreated(
      _collateralToken,
      0,
      _indexToken,
      0,
      0,
      _positionSize,
      _tradeType
    );
  }

  function closePosition(
    address _collateralToken,
    address _indexToken,
    uint256 _positionId
  ) external override {
    // TODO
    emit PositionClosed(_collateralToken, _positionId, 0);
  }
}
