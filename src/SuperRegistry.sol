/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";

/// @title SuperRegistry
/// @author Zeropoint Labs.
/// @dev FIXME: this should be decentralized and protected by a timelock contract.
/// @dev Keeps information on all addresses used in the SuperForms ecosystem.
contract SuperRegistry is ISuperRegistry, AccessControl {
    /// @dev chainId represents the superform chain id.
    uint16 public immutable chainId;

    mapping(bytes32 id => address moduleAddress) private addresses;
    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 bridgeId => address bridgeAddress) public bridgeAddresses;
    mapping(uint8 bridgeId => address ambAddresses) public ambAddresses;

    /// @dev main protocol modules
    bytes32 private constant SUPER_ROUTER = "SUPER_ROUTER";
    bytes32 private constant TOKEN_BANK = "TOKEN_BANK";
    bytes32 private constant SUPERFORM_FACTORY = "SUPERFORM_FACTORY";
    bytes32 private constant CORE_STATE_REGISTRY = "CORE_STATE_REGISTRY";
    bytes32 private constant FACTORY_STATE_REGISTRY = "FACTORY_STATE_REGISTRY";
    bytes32 private constant SUPER_POSITIONS = "SUPER_POSITIONS";

    /// @dev sets caller as the admin of the contract.
    /// @param chainId_ the superform chain id this registry is deployed on
    constructor(uint16 chainId_) {
        if (chainId_ == 0) revert INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function setAddress(
        bytes32 id,
        address newAddress
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldAddress = addresses[id];
        addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperRouter(
        address superRouter_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superRouter_ == address(0)) revert ZERO_ADDRESS();

        address oldSuperRouter = addresses[SUPER_ROUTER];
        addresses[SUPER_ROUTER] = superRouter_;

        emit SuperRouterUpdated(oldSuperRouter, superRouter_);
    }

    /// @inheritdoc ISuperRegistry
    function setTokenBank(
        address tokenBank_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenBank_ == address(0)) revert ZERO_ADDRESS();

        address oldTokenBank = addresses[TOKEN_BANK];
        addresses[TOKEN_BANK] = tokenBank_;

        emit TokenBankUpdated(oldTokenBank, tokenBank_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperFormFactory(
        address superFormFactory_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superFormFactory_ == address(0)) revert ZERO_ADDRESS();

        address oldSuperFormFactory = addresses[SUPERFORM_FACTORY];
        addresses[SUPERFORM_FACTORY] = superFormFactory_;

        emit SuperFormFactoryUpdated(oldSuperFormFactory, superFormFactory_);
    }

    /// @inheritdoc ISuperRegistry
    function setCoreStateRegistry(
        address coreStateRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (coreStateRegistry_ == address(0)) revert ZERO_ADDRESS();

        address oldCoreStateRegistry = addresses[CORE_STATE_REGISTRY];
        addresses[CORE_STATE_REGISTRY] = coreStateRegistry_;

        emit CoreStateRegistryUpdated(oldCoreStateRegistry, coreStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    function setFactoryStateRegistry(
        address factoryStateRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factoryStateRegistry_ == address(0)) revert ZERO_ADDRESS();

        address oldFactoryStateRegistry = addresses[FACTORY_STATE_REGISTRY];
        addresses[FACTORY_STATE_REGISTRY] = factoryStateRegistry_;

        emit FactoryStateRegistryUpdated(
            oldFactoryStateRegistry,
            factoryStateRegistry_
        );
    }

    /// @inheritdoc ISuperRegistry
    function setSuperPositions(
        address superPositions_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superPositions_ == address(0)) revert ZERO_ADDRESS();

        address oldSuperPositions = addresses[SUPER_POSITIONS];
        addresses[SUPER_POSITIONS] = superPositions_;

        emit SuperPositionsUpdated(oldSuperPositions, superPositions_);
    }

    /// @inheritdoc ISuperRegistry
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            address x = bridgeAddress_[i];
            uint8 y = bridgeId_[i];
            if (x == address(0)) revert ZERO_ADDRESS();

            bridgeAddresses[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /// @inheritdoc ISuperRegistry

    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < ambId_.length; i++) {
            address x = ambAddress_[i];
            uint8 y = ambId_[i];
            if (x == address(0)) revert ZERO_ADDRESS();

            ambAddresses[y] = x;
            emit SetAmbAddress(y, x);
        }
    }

    /*///////////////////////////////////////////////////////////////
                    External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function getAddress(bytes32 id) public view override returns (address) {
        return addresses[id];
    }

    /// @inheritdoc ISuperRegistry
    function superRouter()
        external
        view
        override
        returns (address superRouter_)
    {
        superRouter_ = getAddress(SUPER_ROUTER);
    }

    /// @inheritdoc ISuperRegistry
    function tokenBank() external view override returns (address tokenBank_) {
        tokenBank_ = getAddress(TOKEN_BANK);
    }

    /// @inheritdoc ISuperRegistry
    function superFormFactory()
        external
        view
        override
        returns (address superFormFactory_)
    {
        superFormFactory_ = getAddress(SUPERFORM_FACTORY);
    }

    /// @inheritdoc ISuperRegistry
    function coreStateRegistry()
        external
        view
        override
        returns (address coreStateRegistry_)
    {
        coreStateRegistry_ = getAddress(CORE_STATE_REGISTRY);
    }

    /// @inheritdoc ISuperRegistry
    function factoryStateRegistry()
        external
        view
        override
        returns (address factoryStateRegistry_)
    {
        factoryStateRegistry_ = getAddress(FACTORY_STATE_REGISTRY);
    }

    /// @inheritdoc ISuperRegistry
    function superPositions()
        external
        view
        override
        returns (address superPositions_)
    {
        superPositions_ = getAddress(SUPER_POSITIONS);
    }

    /// @inheritdoc ISuperRegistry
    function getBridgeAddress(
        uint8 bridgeId_
    ) external view override returns (address bridgeAddress_) {
        bridgeAddress_ = bridgeAddresses[bridgeId_];
    }

    /// @inheritdoc ISuperRegistry
    function getAmbAddress(
        uint8 ambId_
    ) external view override returns (address ambAddress_) {
        ambAddress_ = ambAddresses[ambId_];
    }
}
