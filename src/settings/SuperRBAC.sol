///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IBroadcaster} from "../interfaces/IBroadcaster.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";
import {AMBFactoryMessage, AMBMessage} from "../types/DataTypes.sol";

/// @title SuperRBAC
/// @author Zeropoint Labs.
/// @dev Contract to manage roles in the entire superForm protocol
contract SuperRBAC is ISuperRBAC, AccessControl {
    uint8 public constant STATE_REGISTRY_TYPE = 2;

    bytes32 public immutable PROTOCOL_ADMIN_ROLE = keccak256("PROTOCOL_ADMIN_ROLE");
    bytes32 public constant override EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN_ROLE");
    bytes32 public constant override FEE_ADMIN_ROLE = keccak256("FEE_ADMIN_ROLE");
    bytes32 public constant override SYNC_REVOKE_ROLE = keccak256("SYNC_REVOKE_ROLE");
    bytes32 public constant override SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 public constant override CORE_CONTRACTS_ROLE = keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant override PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant override TWOSTEPS_PROCESSOR_ROLE = keccak256("TWOSTEPS_PROCESSOR_ROLE");
    bytes32 public constant override UPDATER_ROLE = keccak256("UPDATER_ROLE");

    ISuperRegistry public superRegistry;

    constructor(address admin_) {
        _setupRole(PROTOCOL_ADMIN_ROLE, admin_);

        _setRoleAdmin(FEE_ADMIN_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(PROTOCOL_ADMIN_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(EMERGENCY_ADMIN_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(SWAPPER_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(CORE_CONTRACTS_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(PROCESSOR_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(TWOSTEPS_PROCESSOR_ROLE, PROTOCOL_ADMIN_ROLE);
        _setRoleAdmin(UPDATER_ROLE, PROTOCOL_ADMIN_ROLE);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    function setSuperRegistry(address superRegistry_) external override onlyRole(PROTOCOL_ADMIN_ROLE) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /// @inheritdoc ISuperRBAC
    function grantProtocolAdminRole(address admin_) external override {
        grantRole(PROTOCOL_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function grantFeeAdminRole(address admin_) external override {
        grantRole(FEE_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeProtocolAdminRole(address admin_) external override {
        revokeRole(PROTOCOL_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function grantEmergencyAdminRole(address admin_) external override {
        grantRole(EMERGENCY_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeEmergencyAdminRole(address admin_) external override {
        revokeRole(EMERGENCY_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function grantSwapperRole(address swapper_) external override {
        grantRole(SWAPPER_ROLE, swapper_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSwapperRole(address swapper_, bytes memory extraData_) external payable override {
        revokeRole(SWAPPER_ROLE, swapper_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(SWAPPER_ROLE, swapper_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantCoreContractsRole(address coreContracts_) external override {
        grantRole(CORE_CONTRACTS_ROLE, coreContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeCoreContractsRole(address coreContracts_, bytes memory extraData_) external payable override {
        revokeRole(CORE_CONTRACTS_ROLE, coreContracts_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(CORE_CONTRACTS_ROLE, coreContracts_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantProcessorRole(address processor_) external override {
        grantRole(PROCESSOR_ROLE, processor_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeProcessorRole(address processor_, bytes memory extraData_) external payable override {
        revokeRole(PROCESSOR_ROLE, processor_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(PROCESSOR_ROLE, processor_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantTwoStepsProcessorRole(address twoStepsProcessor_) external override {
        grantRole(TWOSTEPS_PROCESSOR_ROLE, twoStepsProcessor_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeTwoStepsProcessorRole(
        address twoStepsProcessor_,
        bytes memory extraData_
    ) external payable override {
        revokeRole(TWOSTEPS_PROCESSOR_ROLE, twoStepsProcessor_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(TWOSTEPS_PROCESSOR_ROLE, twoStepsProcessor_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantUpdaterRole(address updater_) external override {
        grantRole(UPDATER_ROLE, updater_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeUpdaterRole(address updater_, bytes memory extraData_) external payable override {
        revokeRole(UPDATER_ROLE, updater_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(UPDATER_ROLE, updater_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function stateSync(bytes memory data_) external override {
        if (msg.sender != superRegistry.rolesStateRegistry()) revert Error.NOT_ROLES_STATE_REGISTRY();

        AMBFactoryMessage memory rolesPayload = abi.decode(data_, (AMBFactoryMessage));

        if (rolesPayload.messageType == SYNC_REVOKE_ROLE) {
            (bytes32 role, address affectedAddress) = abi.decode(rolesPayload.message, (bytes32, address));

            /// @dev no one can update the default admin role
            if (role != PROTOCOL_ADMIN_ROLE) revokeRole(role, affectedAddress);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRBAC
    function hasProtocolAdminRole(address admin_) external view override returns (bool) {
        return hasRole(PROTOCOL_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function hasFeeAdminRole(address admin_) external view override returns (bool) {
        return hasRole(FEE_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function hasEmergencyAdminRole(address emergencyAdmin_) external view override returns (bool) {
        return hasRole(EMERGENCY_ADMIN_ROLE, emergencyAdmin_);
    }

    /// @inheritdoc ISuperRBAC
    function hasSyncRevokeRole(address syncRevoker_) external view override returns (bool) {
        return hasRole(SYNC_REVOKE_ROLE, syncRevoker_);
    }

    /// @inheritdoc ISuperRBAC
    function hasSwapperRole(address swapper_) external view override returns (bool) {
        return hasRole(SWAPPER_ROLE, swapper_);
    }

    /// @inheritdoc ISuperRBAC
    function hasCoreContractsRole(address coreContracts_) external view override returns (bool) {
        return hasRole(CORE_CONTRACTS_ROLE, coreContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function hasProcessorRole(address processor_) external view override returns (bool) {
        return hasRole(PROCESSOR_ROLE, processor_);
    }

    /// @inheritdoc ISuperRBAC
    function hasTwoStepsProcessorRole(address twoStepsProcessor_) external view override returns (bool) {
        return hasRole(TWOSTEPS_PROCESSOR_ROLE, twoStepsProcessor_);
    }

    /// @inheritdoc ISuperRBAC
    function hasUpdaterRole(address updater_) external view override returns (bool) {
        return hasRole(UPDATER_ROLE, updater_);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev interacts with role state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(extraData_, (uint8[], bytes));

        /// @dev ambIds are validated inside the factory state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcaster(superRegistry.rolesStateRegistry()).broadcastPayload{value: msg.value}(
            msg.sender,
            ambIds,
            message_,
            broadcastParams
        );
    }
}
