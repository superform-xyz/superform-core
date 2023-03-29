// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface ISuperRegistry {
    /*///////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when an address is being set to 0
    error ZERO_ADDRESS();

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(
        uint256 indexed bridgeId,
        address indexed bridgeAddress
    );

    /// @dev is emitted when the super router address is set.
    event SuperRouterUpdated(address indexed superRouter);

    /// @dev is emitted when the token bank address is set.
    event TokenBankUpdated(address indexed tokenBank);

    /// @dev is emitted when the superform factory address is set.
    event SuperFormFactoryUpdated(address indexed superFormFactory);

    /// @dev is emitted when the state registry address is set.
    event CoreStateRegistryUpdated(address indexed coreStateRegistry);

    /// @dev is emitted when the state registry address is set.
    event FactoryStateRegistryUpdated(address indexed factoryStateRegistry);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

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

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

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

    /// @dev gets the state registry address.
    /// @return factoryStateRegistry_ the address of the state registry
    function factoryStateRegistry()
        external
        view
        returns (address factoryStateRegistry_);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(
        uint8 bridgeId_
    ) external view returns (address bridgeAddress_);
}
