///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";

/// @title SuperRBAC
/// @author Zeropoint Labs.
/// @dev Contract to manage roles in the entire superForm protocol
contract SuperRBAC is ISuperRBAC, AccessControl {
    bytes32 public constant override CORE_STATE_REGISTRY_ROLE =
        keccak256("CORE_STATE_REGISTRY_ROLE");
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

    ISuperRegistry public immutable superRegistry;
    /// @dev chainId represents the superform chain id of the specific chain.
    uint16 public immutable chainId;

    /// @param chainId_              Superform chain id
    /// @param superRegistry_ the superform registry contract
    constructor(uint16 chainId_, address superRegistry_) {
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        superRegistry = ISuperRegistry(superRegistry_);

        address protocolAdmin = superRegistry.protocolAdmin();
        if (msg.sender != protocolAdmin) revert Error.INVALID_DEPLOYER();

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
        address stateRegistry_
    ) external override {
        revokeRole(CORE_STATE_REGISTRY_ROLE, stateRegistry_);
    }

    /// @inheritdoc ISuperRBAC
    function grantSuperRouterRole(address superRouter_) external override {
        grantRole(SUPER_ROUTER_ROLE, superRouter_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSuperRouterRole(address superRouter_) external override {
        revokeRole(SUPER_ROUTER_ROLE, superRouter_);
    }

    /// @inheritdoc ISuperRBAC
    function grantTokenBankRole(address tokenBank_) external override {
        grantRole(TOKEN_BANK_ROLE, tokenBank_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeTokenBankRole(address tokenBank_) external override {
        revokeRole(TOKEN_BANK_ROLE, tokenBank_);
    }

    /// @inheritdoc ISuperRBAC
    function grantSuperformFactoryRole(
        address superformFactory_
    ) external override {
        grantRole(SUPERFORM_FACTORY_ROLE, superformFactory_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSuperformFactoryRole(
        address superformFactory_
    ) external override {
        revokeRole(SUPERFORM_FACTORY_ROLE, superformFactory_);
    }

    /// @inheritdoc ISuperRBAC
    function grantSwapperRole(address swapper_) external override {
        grantRole(SWAPPER_ROLE, swapper_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeSwapperRole(address swapper_) external override {
        revokeRole(SWAPPER_ROLE, swapper_);
    }

    /// @inheritdoc ISuperRBAC
    function grantCoreContractsRole(address coreContracts_) external override {
        grantRole(CORE_CONTRACTS_ROLE, coreContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeCoreContractsRole(address coreContracts_) external override {
        revokeRole(CORE_CONTRACTS_ROLE, coreContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function grantImplementationContractsRole(
        address implementationContracts_
    ) external override {
        grantRole(IMPLEMENTATION_CONTRACTS_ROLE, implementationContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeImplementationContractsRole(
        address implementationContracts_
    ) external override {
        revokeRole(IMPLEMENTATION_CONTRACTS_ROLE, implementationContracts_);
    }

    /// @inheritdoc ISuperRBAC
    function grantProcessorRole(address processor_) external override {
        grantRole(PROCESSOR_ROLE, processor_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeProcessorRole(address processor_) external override {
        revokeRole(PROCESSOR_ROLE, processor_);
    }

    /// @inheritdoc ISuperRBAC
    function grantUpdaterRole(address updater_) external override {
        grantRole(UPDATER_ROLE, updater_);
    }

    /// @inheritdoc ISuperRBAC
    function revokeUpdaterRole(address updater_) external override {
        revokeRole(UPDATER_ROLE, updater_);
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

    /// @inheritdoc ISuperRBAC
    function hasSuperRouterRole(
        address superRouter_
    ) external view override returns (bool) {
        return hasRole(SUPER_ROUTER_ROLE, superRouter_);
    }

    /// @inheritdoc ISuperRBAC
    function hasTokenBankRole(
        address tokenBank_
    ) external view override returns (bool) {
        return hasRole(TOKEN_BANK_ROLE, tokenBank_);
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
}
