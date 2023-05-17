///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";
import {AMBFactoryMessage, AMBMessage} from "../types/DataTypes.sol";
import "../utils/DataPacking.sol";
import "forge-std/console.sol";

/// @title SuperRBAC
/// @author Zeropoint Labs.
/// @dev Contract to manage roles in the entire superForm protocol
contract SuperRBAC is ISuperRBAC, AccessControl {
    uint8 public constant STATE_REGISTRY_TYPE = 2;

    bytes32 public constant SYNC_REVOKE_ROLE = keccak256("SYNC_REVOKE_ROLE");

    bytes32 public constant override CORE_STATE_REGISTRY_ROLE =
        keccak256("CORE_STATE_REGISTRY_ROLE");
    bytes32 public constant FORM_STATE_REGISTRY_ROLE =
        keccak256("FORM_STATE_REGISTRY_ROLE");
    bytes32 public constant override SUPER_ROUTER_ROLE =
        keccak256("SUPER_ROUTER_ROLE");
    bytes32 public constant override TOKEN_BANK_ROLE =
        keccak256("TOKEN_BANK_ROLE");
    bytes32 public constant override SUPERFORM_FACTORY_ROLE =
        keccak256("SUPERFORM_FACTORY_ROLE");
    bytes32 public constant override SWAPPER_ROLE = keccak256("SWAPPER_ROLE");
    bytes32 public constant override CORE_CONTRACTS_ROLE =
        keccak256("CORE_CONTRACTS_ROLE");
    bytes32 public constant override IMPLEMENTATION_CONTRACTS_ROLE =
        keccak256("IMPLEMENTATION_CONTRACTS_ROLE");
    bytes32 public constant override PROCESSOR_ROLE =
        keccak256("PROCESSOR_ROLE");
    bytes32 public constant override UPDATER_ROLE = keccak256("UPDATER_ROLE");
    bytes32 public constant override SUPER_POSITIONS_BANK_ROLE =
        keccak256("SUPER_POSITIONS_BANK_ROLE");

    ISuperRegistry public immutable superRegistry;

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_, address admin_) {
        superRegistry = ISuperRegistry(superRegistry_);

        address protocolAdmin = superRegistry.protocolAdmin();
        if (admin_ != protocolAdmin) revert Error.INVALID_DEPLOYER();

        _setupRole(DEFAULT_ADMIN_ROLE, protocolAdmin);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRBAC
    function grantProtocolAdminRole(address admin_) external override {
        grantRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeProtocolAdminRole(address admin_) external override {
        revokeRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function grantCoreStateRegistryRole(
        address coreStateRegistry_
    ) external override {
        grantRole(CORE_STATE_REGISTRY_ROLE, coreStateRegistry_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeCoreStateRegistryRole(
        address stateRegistry_,
        bytes memory extraData_
    ) external payable override {
        revokeRole(CORE_STATE_REGISTRY_ROLE, stateRegistry_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(CORE_STATE_REGISTRY_ROLE, stateRegistry_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// TODO: inheritdoc ISuperRBAC
    function grantFormStateRegistryRole(address formStateRegistry_) external {
        grantRole(FORM_STATE_REGISTRY_ROLE, formStateRegistry_);
    }

    /// TODO: inheritdoc ISuperRBAC
    function revokeFormStateRegistryRole(address formStateRegistry_) external {
        revokeRole(FORM_STATE_REGISTRY_ROLE, formStateRegistry_);
    }

    /// @inheritdoc ISuperRBAC
    function grantSuperRouterRole(address superRouter_) external override {
        grantRole(SUPER_ROUTER_ROLE, superRouter_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSuperRouterRole(
        address superRouter_,
        bytes memory extraData_
    ) external payable override {
        revokeRole(SUPER_ROUTER_ROLE, superRouter_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(SUPER_ROUTER_ROLE, superRouter_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantTokenBankRole(address tokenBank_) external override {
        grantRole(TOKEN_BANK_ROLE, tokenBank_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeTokenBankRole(
        address tokenBank_,
        bytes memory extraData_
    ) external payable override {
        revokeRole(TOKEN_BANK_ROLE, tokenBank_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(TOKEN_BANK_ROLE, tokenBank_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantSuperformFactoryRole(
        address superformFactory_
    ) external override {
        grantRole(SUPERFORM_FACTORY_ROLE, superformFactory_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSuperformFactoryRole(
        address superformFactory_,
        bytes memory extraData_
    ) external payable override {
        revokeRole(SUPERFORM_FACTORY_ROLE, superformFactory_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(SUPERFORM_FACTORY_ROLE, superformFactory_)
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantSwapperRole(address swapper_) external override {
        grantRole(SWAPPER_ROLE, swapper_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSwapperRole(
        address swapper_,
        bytes memory extraData_
    ) external payable override {
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
    function revokeCoreContractsRole(
        address coreContracts_,
        bytes memory extraData_
    ) external payable override {
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
    function grantImplementationContractsRole(
        address implementationContracts_
    ) external override {
        grantRole(IMPLEMENTATION_CONTRACTS_ROLE, implementationContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeImplementationContractsRole(
        address implementationContracts_,
        bytes memory extraData_
    ) external payable override {
        revokeRole(IMPLEMENTATION_CONTRACTS_ROLE, implementationContracts_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory rolesPayload = AMBFactoryMessage(
                SYNC_REVOKE_ROLE,
                abi.encode(
                    IMPLEMENTATION_CONTRACTS_ROLE,
                    implementationContracts_
                )
            );

            _broadcast(abi.encode(rolesPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperRBAC
    function grantProcessorRole(address processor_) external override {
        grantRole(PROCESSOR_ROLE, processor_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeProcessorRole(
        address processor_,
        bytes memory extraData_
    ) external payable override {
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
    function grantUpdaterRole(address updater_) external override {
        grantRole(UPDATER_ROLE, updater_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeUpdaterRole(
        address updater_,
        bytes memory extraData_
    ) external payable override {
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
        if (msg.sender != superRegistry.rolesStateRegistry())
            revert Error.NOT_ROLES_STATE_REGISTRY();

        AMBMessage memory stateRegistryPayload = abi.decode(
            data_,
            (AMBMessage)
        );
        AMBFactoryMessage memory rolesPayload = abi.decode(
            stateRegistryPayload.params,
            (AMBFactoryMessage)
        );

        if (rolesPayload.messageType == SYNC_REVOKE_ROLE) {
            (bytes32 role, address affectedAddress) = abi.decode(
                rolesPayload.message,
                (bytes32, address)
            );

            /// @dev no one can update the default admin role
            if (role != DEFAULT_ADMIN_ROLE) revokeRole(role, affectedAddress);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRBAC
    function hasProtocolAdminRole(
        address admin_
    ) external view override returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc ISuperRBAC
    function hasCoreStateRegistryRole(
        address coreStateRegistry_
    ) external view override returns (bool) {
        return hasRole(CORE_STATE_REGISTRY_ROLE, coreStateRegistry_);
    }

    function hasFormStateRegistryRole(
        address coreStateRegistry_
    ) external view returns (bool) {
        return hasRole(FORM_STATE_REGISTRY_ROLE, coreStateRegistry_);
    }

    /// @inheritdoc ISuperRBAC
    function hasSuperRouterRole(
        address superRouter_
    ) external view override returns (bool) {
        return hasRole(SUPER_ROUTER_ROLE, superRouter_);
    }

    /// @inheritdoc ISuperRBAC
    function hasSuperformFactoryRole(
        address superformFactory_
    ) external view override returns (bool) {
        return hasRole(SUPERFORM_FACTORY_ROLE, superformFactory_);
    }

    /// @inheritdoc ISuperRBAC
    function hasSwapperRole(
        address swapper_
    ) external view override returns (bool) {
        return hasRole(SWAPPER_ROLE, swapper_);
    }

    /// @inheritdoc ISuperRBAC
    function hasCoreContractsRole(
        address coreContracts_
    ) external view override returns (bool) {
        return hasRole(CORE_CONTRACTS_ROLE, coreContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function hasImplementationContractsRole(
        address implementationContracts_
    ) external view override returns (bool) {
        return hasRole(IMPLEMENTATION_CONTRACTS_ROLE, implementationContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function hasProcessorRole(
        address processor_
    ) external view override returns (bool) {
        return hasRole(PROCESSOR_ROLE, processor_);
    }

    /// @inheritdoc ISuperRBAC
    function hasUpdaterRole(
        address updater_
    ) external view override returns (bool) {
        return hasRole(UPDATER_ROLE, updater_);
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev interacts with role state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(
            extraData_,
            (uint8[], bytes)
        );

        /// @dev ambIds are validated inside the factory state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBaseStateRegistry(superRegistry.rolesStateRegistry()).broadcastPayload{
            value: msg.value
        }(ambIds, message_, broadcastParams);
    }
}
