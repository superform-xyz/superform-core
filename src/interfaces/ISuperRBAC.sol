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

    /// @dev grants the EMERGENCY_ADMIN_ROLE to the given address
    /// @param admin_ the address to grant the role to
    function grantEmergencyAdminRole(address admin_) external;

    /// @dev revokes the EMERGENCY_ADMIN_ROLE from given address
    /// @param admin_ the address to revoke the role from
    function revokeEmergencyAdminRole(address admin_) external;

    /// @dev grants the SWAPPER_ROLE to the given address
    /// @param swapper_ the address to grant the role to
    function grantSwapperRole(address swapper_) external;

    /// @dev revokes the SWAPPER_ROLE from given address
    /// @param swapper_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeSwapperRole(address swapper_, bytes memory extraData_) external payable;

    /// @dev grants the CORE_CONTRACTS_ROLE to the given address
    /// @param coreContracts_ the address to grant the role to
    function grantCoreContractsRole(address coreContracts_) external;

    /// @dev revokes the CORE_CONTRACTS_ROLE from given address
    /// @param coreContracts_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeCoreContractsRole(address coreContracts_, bytes memory extraData_) external payable;

    /// @dev grants the PROCESSOR_ROLE to the given address
    /// @param processor_ the address to grant the role to
    function grantProcessorRole(address processor_) external;

    /// @dev revokes the PROCESSOR_ROLE from given address
    /// @param processor_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeProcessorRole(address processor_, bytes memory extraData_) external payable;

    /// @dev grants the TWO_STEPS_PROCESSOR_ROLE to the given address
    /// @param twoStepsProcessor_ the address to grant the role to
    function grantTwoStepsProcessorRole(address twoStepsProcessor_) external;

    /// @dev revokes the TWO_STEPS_PROCESSOR_ROLE from given address
    /// @param twoStepsProcessor_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeTwoStepsProcessorRole(address twoStepsProcessor_, bytes memory extraData_) external payable;

    /// @dev grants the UPDATER_ROLE to the given address
    /// @param updater_ the address to grant the role to
    function grantUpdaterRole(address updater_) external;

    /// @dev revokes the UPDATER_ROLE from given address
    /// @param updater_ the address to revoke the role from
    /// @param extraData_ amb config if broadcasting is required
    /// @notice send extraData_ as bytes(0) if no broadcasting is required
    function revokeUpdaterRole(address updater_, bytes memory extraData_) external payable;

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

    /// @dev returns the id of the sync revoke role
    function SYNC_REVOKE_ROLE() external view returns (bytes32);

    /// @dev returns the id of the swapper role
    function SWAPPER_ROLE() external view returns (bytes32);

    /// @dev returns the id of the core contracts role
    function CORE_CONTRACTS_ROLE() external view returns (bytes32);

    /// @dev returns the id of the processor role
    function PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the two steps processor role
    function TWOSTEPS_PROCESSOR_ROLE() external view returns (bytes32);

    /// @dev returns the id of the updater role
    function UPDATER_ROLE() external view returns (bytes32);

    /// @dev returns wether the given address has the protocol admin role
    /// @param admin_ the address to check
    function hasProtocolAdminRole(address admin_) external view returns (bool);

    /// @dev returns wether the given address has the emergency admin role
    /// @param admin_ the address to check
    function hasEmergencyAdminRole(address admin_) external view returns (bool);

    /// @dev returns wether the given address has the sync revoke role
    /// @param syncRevoke_ the address to check
    function hasSyncRevokeRole(address syncRevoke_) external view returns (bool);

    /// @dev returns wether the given address has the swapper role
    /// @param swapper_ the address to check
    function hasSwapperRole(address swapper_) external view returns (bool);

    /// @dev returns wether the given address has the core contracts role
    /// @param coreContracts_ the address to check
    function hasCoreContractsRole(address coreContracts_) external view returns (bool);

    /// @dev returns wether the given address has the processor role
    /// @param processor_ the address to check
    function hasProcessorRole(address processor_) external view returns (bool);

    /// @dev returns wether the given address has the two steps processor role
    /// @param twoStepsProcessor_ the address to check
    function hasTwoStepsProcessorRole(address twoStepsProcessor_) external view returns (bool);

    /// @dev returns wether the given address has the updater role
    /// @param updater_ the address to check
    function hasUpdaterRole(address updater_) external view returns (bool);
}
