// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ISuperRegistry
/// @author Zeropoint Labs.
/// @dev interface for Super Registry
interface ISuperRegistry {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event SetImmutables(uint256 indexed chainId, address indexed permit2);

    /// @dev is emitted when an address is set.
    event ProtocolAddressUpdated(
        bytes32 indexed protocolAddressId,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @dev is emitted when the super router address is set.
    event SuperRouterUpdated(address indexed oldSuperRouter, address indexed superRouter);

    /// @dev is emitted when the superform factory address is set.
    event SuperFormFactoryUpdated(address indexed oldSuperFormFactory, address indexed superFormFactory);

    /// @dev is emitted when the state registry address is set.
    event CoreStateRegistryUpdated(address indexed oldCoreStateRegistry, address indexed coreStateRegistry);

    /// @dev is emitted when the state registry address is set.
    event TwoStepsFormStateRegistryUpdated(
        address indexed oldTwoStepsFormStateRegistry,
        address indexed twoStepsFormStateRegistry
    );
    /// @dev is emitted when the state registry address is set.
    event FactoryStateRegistryUpdated(address indexed oldFactoryStateRegistry, address indexed factoryStateRegistry);

    /// @dev is emitted when the roles state registry address is set.
    event RolesStateRegistryUpdated(address indexed oldRolesStateRegistry, address indexed rolesStateRegistry);

    /// @dev is emitted when a new super positions is configured.
    event SuperPositionsUpdated(address indexed oldSuperPositions, address indexed superPositions);

    /// @dev is emitted when a new super rbac is configured.
    event SuperRBACUpdated(address indexed oldSuperRBAC, address indexed superRBAC);

    /// @dev is emitted when a new multi tx processor is configured.
    event MultiTxProcessorUpdated(address indexed oldMultiTxProcessor, address indexed multiTxProcessor);

    /// @dev is emitted when a new tx processor is configured.
    event TxProcessorUpdated(address indexed oldTxProcessor, address indexed txProcessor);

    /// @dev is emitted when a new tx updater is configured.
    event TxUpdaterUpdated(address indexed oldTxUpdater, address indexed txUpdater);

    /// @dev is emitted when a new fee collector is configured.
    event FeeCollectorUpdated(address indexed oldFeeCollector, address indexed feeCollector);

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 indexed bridgeId, address indexed bridgeAddress);

    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(uint256 indexed bridgeId, address indexed bridgeValidator);

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 ambId_, address ambAddress_);

    /// @dev is emitted when a new state registry is configured.
    event SetStateRegistryAddress(uint8 registryId_, address registryAddress_);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev sets the chain id.
    /// @param chainId_ the superform chain id this registry is deployed on
    /// @param permit2_ the address of the permit2 contract
    function setImmutables(uint64 chainId_, address permit2_) external;

    /// @dev sets a new protocol address.
    /// @param protocolAddressId_ the protocol address identifier
    /// @param newAddress_ the new address
    function setNewProtocolAddress(bytes32 protocolAddressId_, address newAddress_) external;

    /// @dev sets the super router address.
    /// @param superRouter_ the address of the super router
    function setSuperRouter(address superRouter_) external;

    /// @dev sets the superform factory address.
    /// @param superFormFactory_ the address of the superform factory
    function setSuperFormFactory(address superFormFactory_) external;

    /// @dev sets the superform fee collector address.
    /// @param feeCollector_ the address of the fee collector
    function setFeeCollector(address feeCollector_) external;

    /// @dev sets the state registry address.
    /// @param coreStateRegistry_ the address of the state registry
    function setCoreStateRegistry(address coreStateRegistry_) external;

    /// @dev sets the state registry address.
    /// @param twoStepsFormStateRegistry_ the address of the state registry
    function setTwoStepsFormStateRegistry(address twoStepsFormStateRegistry_) external;

    /// @dev sets the state registry address.
    /// @param factoryStateRegistry_ the address of the state registry
    function setFactoryStateRegistry(address factoryStateRegistry_) external;

    /// @dev sets the state registry address.
    /// @param rolesStateRegistry_ the address of the roles state registry
    function setRolesStateRegistry(address rolesStateRegistry_) external;

    /// @dev allows admin to set the super rbac address
    /// @param superRBAC_ the address of the super rbac
    function setSuperRBAC(address superRBAC_) external;

    /// @dev allows admin to set the multi tx processor address
    /// @param multiTxProcessor_ the address of the multi tx processor
    function setMultiTxProcessor(address multiTxProcessor_) external;

    /// @dev allows admin to set the tx processor address
    /// @param txProcessor_ the address of the tx processor
    function setTxProcessor(address txProcessor_) external;

    /// @dev allows admin to set the tx processor address
    /// @param txUpdater_ the address of the tx updater
    function setTxUpdater(address txUpdater_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    /// @param bridgeValidator_  represents the bridge validator address.
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    ) external;

    /// @dev allows admin to set the amb address for an amb id.
    /// @param ambId_         represents the bridge unqiue identifier.
    /// @param ambAddress_    represents the bridge address.
    function setAmbAddress(uint8[] memory ambId_, address[] memory ambAddress_) external;

    /// @dev allows admin to set the state registry address for an state registry id.
    /// @param registryId_    represents the state registry's unqiue identifier.
    /// @param registryAddress_    represents the state registry's address.
    function setStateRegistryAddress(uint8[] memory registryId_, address[] memory registryAddress_) external;

    /// @dev allows admin to set the super positions address
    /// @param superPositions_ the address of the super positions
    function setSuperPositions(address superPositions_) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev gets the superform chainId of the protocol
    function chainId() external view returns (uint64);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the super router module
    function SUPER_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the superform fee collector
    function FEE_COLLECTOR() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the two steps form state registry module
    function TWO_STEPS_FORM_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the factory state registry module
    function FACTORY_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the factory state registry module
    function ROLES_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the multi tx processor module
    function MULTI_TX_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the tx processor module
    function TX_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the tx updater module
    function TX_UPDATER() external view returns (bytes32);

    /// @dev gets the address of a contract.
    /// @param protocolAddressId_ is the id of the contract
    function getProtocolAddress(bytes32 protocolAddressId_) external view returns (address);

    /// @dev gets the super router address.
    /// @return superRouter_ the address of the super router
    function superRouter() external view returns (address superRouter_);

    /// @dev gets the superform factory address.
    /// @return superFormFactory_ the address of the superform factory
    function superFormFactory() external view returns (address superFormFactory_);

    /// @dev gets the state registry address.
    /// @return coreStateRegistry_ the address of the state registry
    function coreStateRegistry() external view returns (address coreStateRegistry_);

    /// @dev gets the form state registry address.
    /// @return twoStepsFormStateRegistry_ the address of the state registry
    function twoStepsFormStateRegistry() external view returns (address twoStepsFormStateRegistry_);

    /// @dev gets the state registry address.
    /// @return factoryStateRegistry_ the address of the state registry
    function factoryStateRegistry() external view returns (address factoryStateRegistry_);

    /// @dev gets the roles state registry address.
    /// @return rolesStateRegistry_ the address of the state registry
    function rolesStateRegistry() external view returns (address rolesStateRegistry_);

    /// @dev gets the super positions
    /// @return superPositions_ the address of the super positions
    function superPositions() external view returns (address superPositions_);

    /// @dev gets the super rbac
    /// @return superRBAC_ the address of the super rbac
    function superRBAC() external view returns (address superRBAC_);

    /// @dev gets the multi tx processor
    /// @return multiTxProcessor_ the address of the multi tx processor
    function multiTxProcessor() external view returns (address multiTxProcessor_);

    /// @dev gets the tx processor
    /// @return txProcessor_ the address of the tx processor
    function txProcessor() external view returns (address txProcessor_);

    /// @dev gets the tx updater
    /// @return txUpdater_ the address of the tx updater
    function txUpdater() external view returns (address txUpdater_);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(uint8 bridgeId_) external view returns (address bridgeAddress_);

    /// @dev gets the address of the registry
    /// @param registryId_ is the id of the state registry
    /// @return registryAddress_ is the address of the state registry
    function getStateRegistry(uint8 registryId_) external view returns (address registryAddress_);

    /// @dev gets the id of the registry
    /// @notice reverts if the id is not found
    /// @param registryAddress_ is the address of the state registry
    /// @return registryId_ is the id of the state registry
    function getStateRegistryId(address registryAddress_) external view returns (uint8 registryId_);

    /// @dev helps validate if an address is a valid state registry
    /// @param registryAddress_ is the address of the state registry
    /// @return valid_ a flag indicating if its valid.
    function isValidStateRegistry(address registryAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid amb implementation
    /// @param ambAddress_ is the address of the amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(uint8 bridgeId_) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(uint8 ambId_) external view returns (address ambAddress_);

    /// @dev gets the address of fee collector
    /// @return feeCollector_ is the address of the fee collector
    function getFeeCollector() external view returns (address feeCollector_);
}
