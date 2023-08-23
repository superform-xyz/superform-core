// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

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

    /// @dev allows sync of global roles from different chains
    /// @notice may not work for all roles
    function stateSync(bytes memory data_) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the id of the protocol admin role
    function PROTOCOL_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the emergency admin role
    function EMERGENCY_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the payment admin role
    function PAYMENT_ADMIN_ROLE() external view returns (bytes32);

    /// @dev returns the id of the multi tx swapper role
    function MULTI_TX_SWAPPER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core contracts role
    function CORE_CONTRACTS_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor role
    function CORE_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the roles state registry processor role
    function ROLES_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the factory state registry processor role
    function FACTORY_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the two steps state registry processor role
    function TWOSTEPS_STATE_REGISTRY_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater role
    function CORE_STATE_REGISTRY_UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns the id of minter role
    function MINTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of burner role
    function BURNER_ROLE() external view returns (bytes32);

    /// @dev returns the id of minter state registry role
    function MINTER_STATE_REGISTRY_ROLE() external view returns (bytes32);

    /// @dev returns whether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the emergency admin role
    /// @param admin_ the address to check
    function hasEmergencyAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the payment admin role
    /// @param admin_ the address to check
    function hasPaymentAdminRole(address admin_) external view returns (bool);

    /// @dev returns whether the given address has the swapper role
    /// @param swapper_ the address to check
    function hasMultiTxProcessorSwapperRole(address swapper_) external view returns (bool);

    /// @dev returns whether the given address has the core contracts role
    /// @param coreContracts_ the address to check
    function hasCoreContractsRole(address coreContracts_) external view returns (bool);

    /// @dev returns whether the given address has the processor role
    /// @param processor_ the address to check
    function hasCoreStateRegistryProcessorRole(address processor_) external view returns (bool);

    /// @dev returns whether the given address has the processor role
    /// @param processor_ the address to check
    function hasRolesStateRegistryProcessorRole(address processor_) external view returns (bool);

    /// @dev returns whether the given address has the processor role
    /// @param processor_ the address to check
    function hasFactoryStateRegistryProcessorRole(address processor_) external view returns (bool);

    /// @dev returns whether the given address has the two steps processor role
    /// @param twoStepsProcessor_ the address to check
    function hasTwoStepsStateRegistryProcessorRole(address twoStepsProcessor_) external view returns (bool);

    /// @dev returns whether the given address has the updater role
    /// @param updater_ the address to check
    function hasCoreStateRegistryUpdaterRole(address updater_) external view returns (bool);

    /// @dev returns whether the given address has the super positions minter role
    /// @param minter_ the address to check
    function hasMinterRole(address minter_) external view returns (bool);

    /// @dev returns whether the given address has the super positions burner role
    /// @param burner_ the address to check
    function hasBurnerRole(address burner_) external view returns (bool);

    /// @dev returns whether the given state registry address has the minter role
    /// @param stateRegistry_ the address to check
    function hasMinterStateRegistryRole(address stateRegistry_) external view returns (bool);
}
