// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract sERC20 is ERC20, AccessControl {
    bytes32 public constant POSITIONS_SPLITTER_ROLE =
        keccak256("POSITIONS_SPLITTER_ROLE");

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _setupRole(POSITIONS_SPLITTER_ROLE, msg.sender);
    }

    /// @dev Functions could be open (at least burn) and just pass call to SuperRouter
    function mint(
        address owner,
        uint256 amount
    ) external onlyRole(POSITIONS_SPLITTER_ROLE) {
        _mint(owner, amount);
    }

    function burn(
        address owner,
        uint256 amount
    ) external onlyRole(POSITIONS_SPLITTER_ROLE) {
        _burn(owner, amount);
    }
}
