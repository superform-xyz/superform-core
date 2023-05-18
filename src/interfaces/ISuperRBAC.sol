// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ISuperRBAC
/// @author Zeropoint Labs.
/// @dev interface for Super RBAC
interface ISuperRBAC {
    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev grants the DEFAULT_ADMIN_ROLE to the given address
    /// @param admin_ the address to grant the role to
    function grantProtocolAdminRole(address admin_) external;

    /// @dev revokes the DEFAULT_ADMIN_ROLE from given address
    /// @param admin_ the address to revoke the role from
    function revokeProtocolAdminRole(address admin_) external;

    /// @dev grants the CORE_STATE_REGISTRY_ROLE to the given address
    /// @param coreStateRegistry_ the address to grant the role to
    function grantCoreStateRegistryRole(address coreStateRegistry_) external;

    /// @dev revokes the CORE_STATE_REGISTRY_ROLE from given address
    /// @param coreStateRegistry_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeCoreStateRegistryRole(
        address coreStateRegistry_,
        bytes memory extraData_
    ) external payable;

    /// @dev grants the TWOSTEPS_FORM_STATE_REGISTRY_ROLE to the given address
    /// @param twoStepsformStateRegistry_ the address to grant the role to
    function grantTwoStepsFormStateRegistryRole(
        address twoStepsformStateRegistry_
    ) external;

    /// @dev revokes the TWOSTEPS_FORM_STATE_REGISTRY_ROLE from given address
    /// @param twoStepsformStateRegistry_ the address to revoke the role from
    function revokeTwoStepsFormStateRegistryRole(
        address twoStepsformStateRegistry_
    ) external;

    /// @dev grants the SUPER_ROUTER_ROLE to the given address
    /// @param superRouter_ the address to grant the role to
    function grantSuperRouterRole(address superRouter_) external;

    /// @dev revokes the SUPER_ROUTER_ROLE from given address
    /// @param superRouter_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeSuperRouterRole(
        address superRouter_,
        bytes memory extraData_
    ) external payable;

    /// @dev grants the SUPERFORM_FACTORY_ROLE to the given address
    /// @param superformFactory_ the address to grant the role to
    function grantSuperformFactoryRole(address superformFactory_) external;

    /// @dev revokes the SUPERFORM_FACTORY_ROLE from given address
    /// @param superformFactory_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeSuperformFactoryRole(
        address superformFactory_,
        bytes memory extraData_
    ) external payable;

    /// @dev grants the SWAPPER_ROLE to the given address
    /// @param swapper_ the address to grant the role to
    function grantSwapperRole(address swapper_) external;

    /// @dev revokes the SWAPPER_ROLE from given address
    /// @param swapper_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeSwapperRole(
        address swapper_,
        bytes memory extraData_
    ) external payable;

    /// @dev grants the CORE_CONTRACTS_ROLE to the given address
    /// @param coreContracts_ the address to grant the role to
    function grantCoreContractsRole(address coreContracts_) external;

    /// @dev revokes the CORE_CONTRACTS_ROLE from given address
    /// @param coreContracts_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeCoreContractsRole(
        address coreContracts_,
        bytes memory extraData_
    ) external payable;

    /// @dev grants the PROCESSOR_ROLE to the given address
    /// @param processor_ the address to grant the role to
    function grantProcessorRole(address processor_) external;

    /// @dev revokes the PROCESSOR_ROLE from given address
    /// @param processor_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeProcessorRole(
        address processor_,
        bytes memory extraData_
    ) external payable;

    /// @dev grants the UPDATER_ROLE to the given address
    /// @param updater_ the address to grant the role to
    function grantUpdaterRole(address updater_) external;

    /// @dev revokes the UPDATER_ROLE from given address
    /// @param updater_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeUpdaterRole(
        address updater_,
        bytes memory extraData_
    ) external payable;

    /// @dev allows sync of global roles from different chains
    /// @notice may not work for all roles
    function stateSync(bytes memory data_) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/
    /// @dev returns the id of the state registry role
    function CORE_STATE_REGISTRY_ROLE() external view returns (bytes32);

    /// @dev returns the id of the state registry role
    function TWOSTEPS_FORM_STATE_REGISTRY_ROLE()
        external
        view
        returns (bytes32);

    /// @dev returns the id of the super router role
    function SUPER_ROUTER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the superform factory role
    function SUPERFORM_FACTORY_ROLE() external view returns (bytes32);

    /// @dev returns the id of the swapper role
    function SWAPPER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core contracts role
    function CORE_CONTRACTS_ROLE() external view returns (bytes32);

    /// @dev returns the id of the processor role
    function PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the updater role
    function UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns wether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns wether the given address has the core state registry role
    /// @param coreStateRegistry_ the address to check
    function hasCoreStateRegistryRole(
        address coreStateRegistry_
    ) external view returns (bool);

    /// @dev returns wether the given address has the two steps form state registry role
    /// @param twoStepsFormStateRegistry_ the address to check
    function hasTwoStepsFormStateRegistryRole(
        address twoStepsFormStateRegistry_
    ) external view returns (bool);

    /// @dev returns wether the given address has the super router role
    /// @param superRouter_ the address to check
    function hasSuperRouterRole(
        address superRouter_
    ) external view returns (bool);

    /// @dev returns wether the given address has the superform factory role
    /// @param superformFactory_ the address to check
    function hasSuperformFactoryRole(
        address superformFactory_
    ) external view returns (bool);

    /// @dev returns wether the given address has the swapper role
    /// @param swapper_ the address to check
    function hasSwapperRole(address swapper_) external view returns (bool);

    /// @dev returns wether the given address has the core contracts role
    /// @param coreContracts_ the address to check
    function hasCoreContractsRole(
        address coreContracts_
    ) external view returns (bool);

    /// @dev returns wether the given address has the processor role
    /// @param processor_ the address to check
    function hasProcessorRole(address processor_) external view returns (bool);

    /// @dev returns wether the given address has the updater role
    /// @param updater_ the address to check
    function hasUpdaterRole(address updater_) external view returns (bool);
}
