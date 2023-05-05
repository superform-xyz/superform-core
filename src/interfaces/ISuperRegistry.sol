// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

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

    /// @dev is emitted when the protocol admin address is set.
    event ProtocolAdminUpdated(
        address indexed oldProtocolAdmin,
        address indexed protocolAdmin
    );

    /// @dev is emitted when the super router address is set.
    event SuperRouterUpdated(
        address indexed oldSuperRouter,
        address indexed superRouter
    );

    /// @dev is emitted when the token bank address is set.
    event TokenBankUpdated(
        address indexed oldTokenBank,
        address indexed tokenBank
    );

    /// @dev is emitted when the superform factory address is set.
    event SuperFormFactoryUpdated(
        address indexed oldSuperFormFactory,
        address indexed superFormFactory
    );

    /// @dev is emitted when the state registry address is set.
    event CoreStateRegistryUpdated(
        address indexed oldCoreStateRegistry,
        address indexed coreStateRegistry
    );

    /// @dev is emitted when the state registry address is set.
    event FactoryStateRegistryUpdated(
        address indexed oldFactoryStateRegistry,
        address indexed factoryStateRegistry
    );

    /// @dev is emitted when a new super positions is configured.
    event SuperPositionsUpdated(
        address indexed oldSuperPositions,
        address indexed superPositions
    );

    /// @dev is emitted when a new super rbac is configured.
    event SuperRBACUpdated(
        address indexed oldSuperRBAC,
        address indexed superRBAC
    );

    /// @dev is emitted when a new multi tx processor is configured.
    event MultiTxProcessorUpdated(
        address indexed oldMultiTxProcessor,
        address indexed multiTxProcessor
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(
        uint256 indexed bridgeId,
        address indexed bridgeAddress
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetSuperPositionBankAddress(
        address indexed oldBank,
        address indexed bank
    );
    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(
        uint256 indexed bridgeId,
        address indexed bridgeValidator
    );

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 ambId_, address ambAddress_);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev sets the chain id.
    /// @param chainId_ the superform chain id this registry is deployed on
    /// @param permit2_ the address of the permit2 contract
    function setImmutables(uint16 chainId_, address permit2_) external;

    /// @dev sets a new protocol address.
    /// @param protocolAddressId_ the protocol address identifier
    /// @param newAddress_ the new address
    function setNewProtocolAddress(
        bytes32 protocolAddressId_,
        address newAddress_
    ) external;

    /// @dev sets the protocol admin address
    /// @param admin_ the address of the protocol admin
    function setProtocolAdmin(address admin_) external;

    /// @dev sets the super router address.
    /// @param superRouter_ the address of the super router
    function setSuperRouter(address superRouter_) external;

    /// @dev sets the token bank address.
    /// @param tokenBank_ the address of the token bank
    function setTokenBank(address tokenBank_) external;

    /// @dev sets the superform factory address.
    /// @param superFormFactory_ the address of the superform factory
    function setSuperFormFactory(address superFormFactory_) external;

    /// @dev sets the state registry address.
    /// @param coreStateRegistry_ the address of the state registry
    function setCoreStateRegistry(address coreStateRegistry_) external;

    /// @dev sets the state registry address.
    /// @param factoryStateRegistry_ the address of the state registry
    function setFactoryStateRegistry(address factoryStateRegistry_) external;

    /// @dev allows admin to set the super rbac address
    /// @param superRBAC_ the address of the super rbac
    function setSuperRBAC(address superRBAC_) external;

    /// @dev allows admin to set the multi tx processor address
    /// @param multiTxProcessor_ the address of the multi tx processor
    function setMultiTxProcessor(address multiTxProcessor_) external;

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
    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_
    ) external;

    /// @dev allows admin to set the super positions address
    /// @param superPositions_ the address of the super positions
    function setSuperPositions(address superPositions_) external;

    /// @dev allows admin to set the super positions bank address
    /// @param superPositionBank_ the address of the super positions bank
    function setSuperPositionBank(
        address superPositionBank_
    ) external; 

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev gets the superform chainId of the protocol
    function chainId() external view returns (uint16);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the protocol admin
    function PROTOCOL_ADMIN() external view returns (bytes32);

    /// @dev returns the id of the super router module
    function SUPER_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the token bank module
    function TOKEN_BANK() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the form state registry module
    function FORM_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the factory state registry module
    function FACTORY_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super position bank module
    function SUPER_POSITION_BANK() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the multi tx processor module
    function MULTI_TX_PROCESSOR() external view returns (bytes32);

    /// @dev gets the address of a contract.
    /// @param protocolAddressId_ is the id of the contract
    function getProtocolAddress(
        bytes32 protocolAddressId_
    ) external view returns (address);

    /// @dev gets the protocol admin address.
    /// @return protocolAdmin_ the address of the protocol admin
    function protocolAdmin() external view returns (address protocolAdmin_);

    /// @dev gets the super router address.
    /// @return superRouter_ the address of the super router
    function superRouter() external view returns (address superRouter_);

    /// @dev gets the token bank address.
    /// @return tokenBank_ the address of the token bank
    function tokenBank() external view returns (address tokenBank_);

    /// @dev gets the superform factory address.
    /// @return superFormFactory_ the address of the superform factory
    function superFormFactory()
        external
        view
        returns (address superFormFactory_);

    /// @dev gets the state registry address.
    /// @return coreStateRegistry_ the address of the state registry
    function coreStateRegistry()
        external
        view
        returns (address coreStateRegistry_);

    /// @dev gets the form state registry address.
    /// @return formStateRegistry_ the address of the state registry
    function formStateRegistry()
        external
        view
        returns (address formStateRegistry_);

    /// @dev gets the state registry address.
    /// @return factoryStateRegistry_ the address of the state registry
    function factoryStateRegistry()
        external
        view
        returns (address factoryStateRegistry_);

    /// @dev gets the super positions
    /// @return superPositions_ the address of the super positions
    function superPositions() external view returns (address superPositions_);

    /// @dev gets the super rbac
    /// @return superRBAC_ the address of the super rbac
    function superRBAC() external view returns (address superRBAC_);

    /// @dev gets the multi tx processor
    /// @return multiTxProcessor_ the address of the multi tx processor
    function multiTxProcessor()
        external
        view
        returns (address multiTxProcessor_);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(
        uint8 bridgeId_
    ) external view returns (address bridgeAddress_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(
        uint8 bridgeId_
    ) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(
        uint8 ambId_
    ) external view returns (address ambAddress_);

    /// @dev gets the super positions bank
    /// @return superPositionBank_ the address of the super positions bank
    function superPositionBank()
        external
        view
        returns (address superPositionBank_);

}
