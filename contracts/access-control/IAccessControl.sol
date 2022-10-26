// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* IAccessControl.sol
interface for AccessControl
*/

interface IAccessControl {
  function hasRole(address _account, bytes32 _role)
    external
    view
    returns (bool);

  function getRoleCount(bytes32 _role) external view returns (uint256);

  function grantRole(address _account, bytes32 _role) external;

  function revokeRole(address _account, bytes32 _role) external;
}
