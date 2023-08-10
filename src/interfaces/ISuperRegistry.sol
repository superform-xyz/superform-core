// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ISuperRegistry
/// @author Zeropoint Labs.
/// @dev interface for Super Registry
interface ISuperRegistry {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emmitable when pseudo immutable chainId and permit2 address are set
    event SetImmutables(uint256 indexed chainId, address indexed permit2);

    /// @dev is emitted when an address is set.
    event ProtocolAddressUpdated(
        bytes32 indexed protocolAddressId,
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @dev is emitted when an address is set.
    event ProtocolAddressCrossChainUpdated(
        bytes32 indexed protocolAddressId,
        uint64 indexed chainId,
        address indexed oldAddress,
        address newAddress
    );

    /// @dev is emitted when the super router address is set.
    event SuperRouterUpdated(address indexed oldSuperRouter, address indexed superformRouter);

    /// @dev is emitted when the superform factory address is set.
    event SuperformFactoryUpdated(address indexed oldSuperformFactory, address indexed superformFactory);

    /// @dev is emitted when the core state registry address is set for src chain.
    event CoreStateRegistryUpdated(address indexed oldCoreStateRegistry, address indexed coreStateRegistry);

    /// @dev is emitted when the core state registry address is set for a specific chain
    event CoreStateRegistryCrossChainUpdated(
        uint64 indexed chainId,
        address indexed oldCoreStateRegistry,
        address indexed coreStateRegistry
    );

    /// @dev is emitted when the two steps form state registry address is set.
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

    /// @dev is emitted when a new multi tx processor is configured for a specific chain
    event MultiTxProcessorCrossChainUpdated(
        uint64 indexed chainId,
        address indexed oldMultiTxProcessor,
        address indexed multiTxProcessor
    );

    /// @dev is emitted when a new tx processor is configured.
    event TxProcessorUpdated(address indexed oldTxProcessor, address indexed txProcessor);

    /// @dev is emitted when a new fee collector is configured.
    event PayMasterUpdated(address indexed oldPayMaster, address indexed feeCollector);

    /// @dev is emitted when a new payment helper is configured.
    event PaymentHelperUpdated(address indexed oldPaymentHelper, address indexed paymentHelper);

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

    /// @dev sets a new protocol address on a specific chain.
    /// @param protocolAddressId_ the protocol address identifier on that chain
    /// @param newAddress_ the new address on that chain
    /// @param chainId_ the chain id of that chain
    function setNewProtocolAddressCrossChain(bytes32 protocolAddressId_, address newAddress_, uint64 chainId_) external;

    /// @dev sets the super router address.
    /// @param superformRouter_ the address of the super router
    function setSuperRouter(address superformRouter_) external;

    /// @dev sets the superform factory address.
    /// @param superformFactory_ the address of the superform factory
    function setSuperformFactory(address superformFactory_) external;

    /// @dev sets the superform paymaster address.
    /// @param payMaster_ the address of the paymaster contract
    function setPayMaster(address payMaster_) external;

    /// @dev sets the superform payment helper address.
    /// @param paymentHelper_ the address of the payment helper contract
    function setPaymentHelper(address paymentHelper_) external;

    /// @dev sets the core state registry address.
    /// @param coreStateRegistry_ the address of the core state registry
    function setCoreStateRegistry(address coreStateRegistry_) external;

    /// @dev sets the core state registry address in a cross chain fashion
    /// @dev allows admin to set the core state registry address for a specific chain
    /// @param coreStateRegistry_ the address of the core state registry for that chain
    /// @param chainId_ the chain id of that chain
    function setCoreStateRegistryCrossChain(address coreStateRegistry_, uint64 chainId_) external;

    /// @dev sets the two steps form state registry address.
    /// @param twoStepsFormStateRegistry_ the address of the two steps form state registry
    function setTwoStepsFormStateRegistry(address twoStepsFormStateRegistry_) external;

    /// @dev sets the factory state registry address.
    /// @param factoryStateRegistry_ the address of the factory state registry
    function setFactoryStateRegistry(address factoryStateRegistry_) external;

    /// @dev sets the roles state registry address.
    /// @param rolesStateRegistry_ the address of the roles state registry
    function setRolesStateRegistry(address rolesStateRegistry_) external;

    /// @dev allows admin to set the super rbac address
    /// @param superRBAC_ the address of the super rbac
    function setSuperRBAC(address superRBAC_) external;

    /// @dev allows admin to set the multi tx processor address
    /// @param multiTxProcessor_ the address of the multi tx processor
    function setMultiTxProcessor(address multiTxProcessor_) external;

    /// @dev allows admin to set the multi tx processor address for a specific chain
    /// @param multiTxProcessor_ the address of the multi tx processor for that chain
    /// @param chainId_ the chain id of that chain
    function setMultiTxProcessorCrossChain(address multiTxProcessor_, uint64 chainId_) external;

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

    /// @dev returns the id of the superform paymaster contract
    function PAYMASTER() external view returns (bytes32);

    /// @dev returns the id of the superform payload helper contract
    function PAYMENT_HELPER() external view returns (bytes32);

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

    /// @dev gets the address of a contract on a specific chain.
    /// @param protocolAddressId_ is the id of the contract
    /// @param chainId_ is the chain id of that chain
    function getProtocolAddressCrossChain(bytes32 protocolAddressId_, uint64 chainId_) external view returns (address);

    /// @dev gets the super router address.
    /// @return superformRouter_ the address of the super router
    function superformRouter() external view returns (address superformRouter_);

    /// @dev gets the superform factory address.
    /// @return superformFactory_ the address of the superform factory
    function superformFactory() external view returns (address superformFactory_);

    /// @dev gets the core state registry address.
    /// @return coreStateRegistry_ the address of the core state registry
    function coreStateRegistry() external view returns (address coreStateRegistry_);

    /// @dev gets the core state registry address on a specific chain.
    /// @return coreStateRegistry_ the address of the core state registry on that chain
    /// @param chainId_ chain id of that chain
    function coreStateRegistryCrossChain(uint64 chainId_) external view returns (address coreStateRegistry_);

    /// @dev gets the two steps form state registry address.
    /// @return twoStepsFormStateRegistry_ the address of the state registry
    function twoStepsFormStateRegistry() external view returns (address twoStepsFormStateRegistry_);

    /// @dev gets the factory state registry address.
    /// @return factoryStateRegistry_ the address of the factory state registry
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

    /// @dev gets the multi tx processor on a specific chain
    /// @return multiTxProcessor_ the address of the multi tx processor on that chain
    /// @param chainId_ chain id of that chain
    function multiTxProcessorCrossChain(uint64 chainId_) external view returns (address multiTxProcessor_);

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

    /// @dev gets the address of the paymaster
    /// @return payMaster_ is the address of the paymaster contract
    function getPayMaster() external view returns (address payMaster_);

    /// @dev gets the address of the payment helper
    /// @return paymentHelper_ is the address of the payment helper contract
    function getPaymentHelper() external view returns (address paymentHelper_);
}
