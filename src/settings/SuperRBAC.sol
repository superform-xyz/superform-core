///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { AccessControlEnumerable } from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import { IBroadcastRegistry } from "../interfaces/IBroadcastRegistry.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { Error } from "../utils/Error.sol";
import { BroadcastMessage } from "../types/DataTypes.sol";

/// @title SuperRBAC
/// @author Zeropoint Labs.
/// @dev Contract to manage roles in the entire superform protocol
contract SuperRBAC is ISuperRBAC, AccessControlEnumerable {
    bytes32 public constant SYNC_REVOKE = keccak256("SYNC_REVOKE");

    bytes32 public constant override PROTOCOL_ADMIN_ROLE = keccak256("PROTOCOL_ADMIN_ROLE");
    bytes32 public constant override EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");
    bytes32 public constant override PAYMENT_ADMIN_ROLE = keccak256("PAYMENT_ADMIN_ROLE");
    bytes32 public constant override BROADCASTER_ROLE = keccak256("BROADCASTER_ROLE");
    bytes32 public constant override CORE_STATE_REGISTRY_PROCESSOR_ROLE =
        keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE");
    bytes32 public constant override TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE =
        keccak256("TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE");
    bytes32 public constant override BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE =
        keccak256("BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE");
    bytes32 public constant override CORE_STATE_REGISTRY_UPDATER_ROLE = keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE");
    bytes32 public constant override CORE_STATE_REGISTRY_RESCUER_ROLE = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
    bytes32 public constant override CORE_STATE_REGISTRY_DISPUTER_ROLE = keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE");
    bytes32 public constant override SUPERPOSITIONS_MINTER_ROLE = keccak256("SUPERPOSITIONS_MINTER_ROLE");
    bytes32 public constant override SUPERPOSITIONS_BURNER_ROLE = keccak256("SUPERPOSITIONS_BURNER_ROLE");
    bytes32 public constant override SERC20_MINTER_ROLE = keccak256("SERC20_MINTER_ROLE");
    bytes32 public constant override SERC20_BURNER_ROLE = keccak256("SERC20_BURNER_ROLE");
    bytes32 public constant override MINTER_STATE_REGISTRY_ROLE = keccak256("MINTER_STATE_REGISTRY_ROLE");
    bytes32 public constant override WORMHOLE_VAA_RELAYER_ROLE = keccak256("WORMHOLE_VAA_RELAYER_ROLE");
    bytes32 public constant override DST_SWAPPER_ROLE = keccak256("DST_SWAPPER_ROLE");

    ISuperRegistry public superRegistry;

    constructor(address admin_) {
        _setupRole(PROTOCOL_ADMIN_ROLE, admin_);

        /// @dev manually set role admin to PROTOCOL_ADMIN_ROLE on all roles
        _setRoleAdmin(PAYMENT_ADMIN_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(PROTOCOL_ADMIN_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(EMERGENCY_ADMIN_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(CORE_STATE_REGISTRY_PROCESSOR_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(CORE_STATE_REGISTRY_UPDATER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(SUPERPOSITIONS_MINTER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(SUPERPOSITIONS_BURNER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(SERC20_MINTER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(SERC20_BURNER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(MINTER_STATE_REGISTRY_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(BROADCASTER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(WORMHOLE_VAA_RELAYER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(DST_SWAPPER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(CORE_STATE_REGISTRY_RESCUER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(CORE_STATE_REGISTRY_DISPUTER_ROLE, PROTOCOL_ADMIN_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRBAC
    function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// @inheritdoc ISuperRBAC
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {
        _setRoleAdmin(role_, adminRole_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeRoleSuperBroadcast(
        bytes32 role_,
        address addressToRevoke_,
        bytes memory extraData_,
        bytes32 superRegistryAddressId_
    )
        external
        payable
        override
        onlyRole(PROTOCOL_ADMIN_ROLE)
    {
        /// @dev revokeRoleSuperBroadcast cannot update the PROTOCOL_ADMIN_ROLE and EMERGENCY_ADMIN_ROLE
        if (role_ != PROTOCOL_ADMIN_ROLE || role_ != EMERGENCY_ADMIN_ROLE) revokeRole(role_, addressToRevoke_);

        if (extraData_.length > 0) {
            BroadcastMessage memory rolesPayload =
                BroadcastMessage("SUPER_RBAC", SYNC_REVOKE, abi.encode(role_, superRegistryAddressId_));

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function stateSyncBroadcast(bytes memory data_) external override {
        if (msg.sender != superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))) {
            revert Error.NOT_BROADCAST_REGISTRY();
        }

        BroadcastMessage memory rolesPayload = abi.decode(data_, (BroadcastMessage));

        if (rolesPayload.messageType == SYNC_REVOKE) {
            (bytes32 role, bytes32 superRegistryAddressId) = abi.decode(rolesPayload.message, (bytes32, bytes32));
            address addressToRevoke = superRegistry.getAddress(superRegistryAddressId);

            if (addressToRevoke == address(0)) revert Error.ZERO_ADDRESS();

            /// @dev broadcasting cannot update the PROTOCOL_ADMIN_ROLE and EMERGENCY_ADMIN_ROLE
            if (role != PROTOCOL_ADMIN_ROLE || role != EMERGENCY_ADMIN_ROLE) _revokeRole(role, addressToRevoke);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        CONVENIENCE VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRBAC
    function hasProtocolAdminRole(address admin_) external view override returns (bool) {
        if (admin_ == address(0)) return false;
        return hasRole(PROTOCOL_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function hasEmergencyAdminRole(address emergencyAdmin_) external view override returns (bool) {
        return hasRole(EMERGENCY_ADMIN_ROLE, emergencyAdmin_);
    }

    /// @inheritdoc ISuperRBAC
    function hasBroadcasterRole(address broadcaster_) external view override returns (bool) {
        return hasRole(BROADCASTER_ROLE, broadcaster_);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role_, address account_) internal override {
        if (role_ == PROTOCOL_ADMIN_ROLE || role_ == EMERGENCY_ADMIN_ROLE) {
            if (getRoleMemberCount(role_) == 1) revert Error.CANNOT_REVOKE_LAST_ADMIN();
        }
        super._revokeRole(role_, account_);
    }

    /// @dev interacts with role state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(extraData_, (uint8[], bytes));

        /// @dev ambIds are validated inside the factory state registry
        /// @dev if the broadcastParams are wrong, this will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambIds, message_, broadcastParams);
    }
}
