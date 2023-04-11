/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";

/// @title SuperRegistry
/// @author Zeropoint Labs.
/// @dev FIXME: this should be decentralized and protected by a timelock contract.
/// @dev Keeps information on all moduleAddresses used in the SuperForms ecosystem.
contract SuperRegistry is ISuperRegistry, AccessControl {
    /// @dev chainId represents the superform chain id.
    uint16 public immutable chainId;

    mapping(bytes32 id => address moduleAddress) private moduleAddresses;
    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 bridgeId => address bridgeAddress) public bridgeAddresses;
    mapping(uint8 bridgeId => address ambAddresses) public ambAddresses;

    /// @dev main protocol modules
    bytes32 public constant override SUPER_ROUTER = "SUPER_ROUTER";
    bytes32 public constant override TOKEN_BANK = "TOKEN_BANK";
    bytes32 public constant override SUPERFORM_FACTORY = "SUPERFORM_FACTORY";
    bytes32 public constant override CORE_STATE_REGISTRY =
        "CORE_STATE_REGISTRY";
    bytes32 public constant override FACTORY_STATE_REGISTRY =
        "FACTORY_STATE_REGISTRY";
    bytes32 public constant override SUPER_POSITIONS = "SUPER_POSITIONS";

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
    function setNewModule(
        bytes32 moduleId_,
        address newAddress_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldAddress = moduleAddresses[moduleId_];
        moduleAddresses[moduleId_] = newAddress_;
        emit NewModuleUpdated(moduleId_, oldAddress, newAddress_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperRouter(
        address superRouter_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superRouter_ == address(0)) revert ZERO_ADDRESS();

        address oldSuperRouter = moduleAddresses[SUPER_ROUTER];
        moduleAddresses[SUPER_ROUTER] = superRouter_;

        emit SuperRouterUpdated(oldSuperRouter, superRouter_);
    }

    /// @inheritdoc ISuperRegistry
    function setTokenBank(
        address tokenBank_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (tokenBank_ == address(0)) revert ZERO_ADDRESS();

        address oldTokenBank = moduleAddresses[TOKEN_BANK];
        moduleAddresses[TOKEN_BANK] = tokenBank_;

        emit TokenBankUpdated(oldTokenBank, tokenBank_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperFormFactory(
        address superFormFactory_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superFormFactory_ == address(0)) revert ZERO_ADDRESS();

        address oldSuperFormFactory = moduleAddresses[SUPERFORM_FACTORY];
        moduleAddresses[SUPERFORM_FACTORY] = superFormFactory_;

        emit SuperFormFactoryUpdated(oldSuperFormFactory, superFormFactory_);
    }

    /// @inheritdoc ISuperRegistry
    function setCoreStateRegistry(
        address coreStateRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (coreStateRegistry_ == address(0)) revert ZERO_ADDRESS();

        address oldCoreStateRegistry = moduleAddresses[CORE_STATE_REGISTRY];
        moduleAddresses[CORE_STATE_REGISTRY] = coreStateRegistry_;

        emit CoreStateRegistryUpdated(oldCoreStateRegistry, coreStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    function setFactoryStateRegistry(
        address factoryStateRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factoryStateRegistry_ == address(0)) revert ZERO_ADDRESS();

        address oldFactoryStateRegistry = moduleAddresses[
            FACTORY_STATE_REGISTRY
        ];
        moduleAddresses[FACTORY_STATE_REGISTRY] = factoryStateRegistry_;

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

        address oldSuperPositions = moduleAddresses[SUPER_POSITIONS];
        moduleAddresses[SUPER_POSITIONS] = superPositions_;

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
    function getModule(
        bytes32 moduleId_
    ) public view override returns (address) {
        return moduleAddresses[moduleId_];
    }

    /// @inheritdoc ISuperRegistry
    function superRouter()
        external
        view
        override
        returns (address superRouter_)
    {
        superRouter_ = getModule(SUPER_ROUTER);
    }

    /// @inheritdoc ISuperRegistry
    function tokenBank() external view override returns (address tokenBank_) {
        tokenBank_ = getModule(TOKEN_BANK);
    }

    /// @inheritdoc ISuperRegistry
    function superFormFactory()
        external
        view
        override
        returns (address superFormFactory_)
    {
        superFormFactory_ = getModule(SUPERFORM_FACTORY);
    }

    /// @inheritdoc ISuperRegistry
    function coreStateRegistry()
        external
        view
        override
        returns (address coreStateRegistry_)
    {
        coreStateRegistry_ = getModule(CORE_STATE_REGISTRY);
    }

    /// @inheritdoc ISuperRegistry
    function factoryStateRegistry()
        external
        view
        override
        returns (address factoryStateRegistry_)
    {
        factoryStateRegistry_ = getModule(FACTORY_STATE_REGISTRY);
    }

    /// @inheritdoc ISuperRegistry
    function superPositions()
        external
        view
        override
        returns (address superPositions_)
    {
        superPositions_ = getModule(SUPER_POSITIONS);
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
