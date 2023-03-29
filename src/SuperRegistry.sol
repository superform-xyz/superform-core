/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "@openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";

/// @title SuperRegistry
/// @author Zeropoint Labs.
/// @dev FIXME: this should be decentralized and protected by a timelock contract.
/// @dev Keeps information on all addresses used in the SuperForms ecosystem.
contract SuperRegistry is ISuperRegistry, AccessControl {
    /// @dev chainId represents the superform chain id.
    uint16 public immutable chainId;

    address public superRouter;
    address public tokenBank;
    address public superFormFactory;

    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 => address) public bridgeAddress;

    /// @dev sets caller as the admin of the contract.
    /// @param chainId_ the superform chain id this registry is deployed on
    constructor(uint16 chainId_) {
        chainId = chainId_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function setSuperRouter(
        address superRouter_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superRouter_ == address(0)) revert ZERO_ADDRESS();

        superRouter = superRouter_;
    }

    /// @inheritdoc ISuperRegistry
    function setTokenBank(
        address tokenBank_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenBank_ == address(0)) revert ZERO_ADDRESS();

        tokenBank = tokenBank_;
    }

    /// @inheritdoc ISuperRegistry
    function setSuperFormFactory(
        address superFormFactory_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superFormFactory_ == address(0)) revert ZERO_ADDRESS();

        superFormFactory = superFormFactory_;
    }

    /// @inheritdoc ISuperRegistry
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            address x = bridgeAddress_[i];
            uint8 y = bridgeId_[i];
            if (x == address(0)) revert ZERO_ADDRESS();

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /*///////////////////////////////////////////////////////////////
                         External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function getBridgeAddress(
        uint8 bridgeId_
    ) external view override returns (address bridgeAddress_) {
        bridgeAddress_ = bridgeAddress[bridgeId_];
    }
}
