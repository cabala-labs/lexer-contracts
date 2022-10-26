// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/* AccessControl.sol
This contract is used to manage the roles for different address for Lexer
*/

import "./IAccessControl.sol";

contract AccessControl {
  struct RoleData {
    mapping(address => bool) members;
    uint256 memberCount;
  }

  bytes32 public constant SYSTEM_ADMIN = 0x00;

  event RoleGranted(address _account, bytes32 _role);
  event RoleRevoked(address _account, bytes32 _role);

  mapping(bytes32 => RoleData) private _roles;

  constructor() {
    // grant the msg.sender the admin role
    _roles[SYSTEM_ADMIN].members[msg.sender] = true;
  }

  /**
   * @dev check if an given account has a specific role
   */
  function hasRole(address _account, bytes32 _role)
    external
    view
    returns (bool)
  {
    return true; //! override for testing purpose only
    // return _roles[_role].members[_account];
  }

  /**
   * @dev check the number of member in a specific role
   */
  function getRoleCount(bytes32 _role) external view returns (uint256) {
    return _roles[_role].memberCount;
  }

  /**
   * @dev grant an account a given role, by the admin
   */
  function grantRole(address _account, bytes32 _role) public {
    require(_roles[SYSTEM_ADMIN].members[msg.sender], "not admin");
    require(!_roles[_role].members[_account], "already has role");
    _roles[_role].members[_account] = true;
    emit RoleGranted(_account, _role);
  }

  /**
   * @dev revoke an account a given role, by the admin
   */
  function revokeRole(address _account, bytes32 _role) public {
    require(_roles[SYSTEM_ADMIN].members[msg.sender], "not admin");
    require(_roles[_role].members[_account], "does not have role");
    if (_role == SYSTEM_ADMIN) {
      require(_roles[_role].memberCount > 1, "at least one admin required");
    }
    _roles[_role].members[_account] = false;
    emit RoleRevoked(_account, _role);
  }
}
