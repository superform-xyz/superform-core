// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

/// @title ISuperRBAC
/// @author Zeropoint Labs.
/// @dev interface for Super RBAC
interface ISuperRBAC {
    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev updates the super registry address
    function setSuperRegistry(address superRegistry_) external;

    /// @dev configures a new role in superForm
    /// @param role_ the role to set
    /// @param adminRole_ the admin role to set as admin
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) external;

    /// @dev revokes the role_ from superRegistryAddressId_ on all chains
    /// @param role_ the role to revoke
    /// @param addressToRevoke_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @param superRegistryAddressId_ the super registry address id
    function revokeRoleSuperBroadcast(
        bytes32 role_,
        address addressToRevoke_,
        bytes memory extraData_,
        bytes32 superRegistryAddressId_
    )
        external
        payable;

    /// @dev allows sync of global roles from different chains using broadcast registry
    /// @notice may not work for all roles
    function stateSyncBroadcast(bytes memory data_) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the id of the protocol admin role
    function PROTOCOL_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the emergency admin role
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the payment admin role
    function PAYMENT_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcaster role
    function BROADCASTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor role
    function CORE_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the two steps state registry processor role
    function TWOSTEPS_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry processor role
    function BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater role
    function CORE_STATE_REGISTRY_UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns the id of superpositions minter role
    function SUPERPOSITIONS_MINTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of superpositions burner role
    function SUPERPOSITIONS_BURNER_ROLE() external view returns (bytes32);

    /// @dev returns the id of serc20 minter role
    function SERC20_MINTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of serc20 burner role
    function SERC20_BURNER_ROLE() external view returns (bytes32);

    /// @dev returns the id of minter state registry role
    function MINTER_STATE_REGISTRY_ROLE() external view returns (bytes32);

    /// @dev returns the id of wormhole vaa relayer role
    function WORMHOLE_VAA_RELAYER_ROLE() external view returns (bytes32);

    /// @dev returns whether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the emergency admin role
    /// @param admin_ the address to check
    function hasEmergencyAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the broadcaster role
    /// @param broadcaster_ the address to check
    function hasBroadcasterRole(address broadcaster_) external view returns (bool);

    /// @dev returns whether the given address has the payment admin role
    /// @param admin_ the address to check
    function hasPaymentAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the processor role
    /// @param processor_ the address to check
    function hasCoreStateRegistryProcessorRole(address processor_) external view returns (bool);

    /// @dev returns whether the given address has the two steps processor role
    /// @param twoStepsProcessor_ the address to check
    function hasTwoStepsStateRegistryProcessorRole(address twoStepsProcessor_) external view returns (bool);

    /// @dev returns whether the given address has the broadcast processor role
    /// @param broadcastProcessor_ the address to check
    function hasBroadcastStateRegistryProcessorRole(address broadcastProcessor_) external view returns (bool);

    /// @dev returns whether the given address has the updater role
    /// @param updater_ the address to check
    function hasCoreStateRegistryUpdaterRole(address updater_) external view returns (bool);

    /// @dev returns whether the given address has the super positions minter role
    /// @param minter_ the address to check
    function hasSuperPositionsMinterRole(address minter_) external view returns (bool);

    /// @dev returns whether the given address has the super positions burner role
    /// @param burner_ the address to check
    function hasSuperPositionsBurnerRole(address burner_) external view returns (bool);

    /// @dev returns whether the given address has the serc20 minter role
    /// @param minter_ the address to check
    function hasSERC20MinterRole(address minter_) external view returns (bool);

    /// @dev returns whether the given address has the serc20 burner role
    /// @param burner_ the address to check
    function hasSERC20BurnerRole(address burner_) external view returns (bool);

    /// @dev returns whether the given state registry address has the minter state registry role
    /// @param stateRegistry_ the address to check
    function hasMinterStateRegistryRole(address stateRegistry_) external view returns (bool);

    /// @dev returns whether the given relayer_ address has the wormhole relayer role
    /// @param relayer_ the address to check
    function hasWormholeVaaRole(address relayer_) external view returns (bool);
}
