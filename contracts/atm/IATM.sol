// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

interface IATM {
  function transferFrom(
    address _token,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}
