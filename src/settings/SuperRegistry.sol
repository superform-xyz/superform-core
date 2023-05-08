/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IPermit2} from "../interfaces/IPermit2.sol";
import {Error} from "../utils/Error.sol";

/// @title SuperRegistry
/// @author Zeropoint Labs.
/// @dev FIXME: this should be decentralized and protected by a timelock contract.
/// @dev Keeps information on all protocolAddresses used in the SuperForms ecosystem.
contract SuperRegistry is ISuperRegistry, AccessControl {
    /// @dev chainId represents the superform chain id.
    uint16 public chainId;

    /// @dev canonical permit2 contract
    address public PERMIT2;

    mapping(bytes32 id => address moduleAddress) private protocolAddresses;
    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 bridgeId => address bridgeAddress) public bridgeAddresses;
    mapping(uint8 bridgeId => address bridgeValidator) public bridgeValidator;
    mapping(uint8 bridgeId => address ambAddresses) public ambAddresses;

    /// @dev core protocol addresses identifiers
    /// @dev FIXME: we don't have AMB and liquidity bridge implementations here, should we add?
    bytes32 public constant override PROTOCOL_ADMIN = "PROTOCOL_ADMIN";
    bytes32 public constant override SUPER_ROUTER = "SUPER_ROUTER";
    bytes32 public constant override TOKEN_BANK = "TOKEN_BANK";
    bytes32 public constant override SUPERFORM_FACTORY = "SUPERFORM_FACTORY";
    bytes32 public constant override CORE_STATE_REGISTRY =
        "CORE_STATE_REGISTRY";
    bytes32 public constant FORM_STATE_REGISTRY = "FORM_STATE_REGISTRY";
    bytes32 public constant override FACTORY_STATE_REGISTRY =
        "FACTORY_STATE_REGISTRY";
    bytes32 public constant override SUPER_POSITIONS = "SUPER_POSITIONS";
    bytes32 public constant override SUPER_POSITION_BANK =
        "SUPER_POSITION_BANK";
    bytes32 public constant override SUPER_RBAC = "SUPER_RBAC";
    bytes32 public constant override MULTI_TX_PROCESSOR = "MULTI_TX_PROCESSOR";

    /// @param admin_ the address of the admin.
    constructor(address admin_) {
        _setupRole(DEFAULT_ADMIN_ROLE, admin_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function setImmutables(
        uint16 chainId_,
        address permit2_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (chainId != 0) revert Error.DISABLED();
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();
        if (PERMIT2 != address(0)) revert Error.DISABLED();

        chainId = chainId_;
        PERMIT2 = permit2_;

        emit SetImmutables(chainId_, PERMIT2);
    }

    /// @inheritdoc ISuperRegistry
    function setNewProtocolAddress(
        bytes32 protocolAddressId_,
        address newAddress_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        address oldAddress = protocolAddresses[protocolAddressId_];
        protocolAddresses[protocolAddressId_] = newAddress_;
        emit ProtocolAddressUpdated(
            protocolAddressId_,
            oldAddress,
            newAddress_
        );
    }

    /// @inheritdoc ISuperRegistry
    function setProtocolAdmin(
        address admin_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (admin_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldAdmin = protocolAddresses[PROTOCOL_ADMIN];
        protocolAddresses[PROTOCOL_ADMIN] = admin_;

        emit ProtocolAdminUpdated(oldAdmin, admin_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperRouter(
        address superRouter_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superRouter_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldSuperRouter = protocolAddresses[SUPER_ROUTER];
        protocolAddresses[SUPER_ROUTER] = superRouter_;

        emit SuperRouterUpdated(oldSuperRouter, superRouter_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperFormFactory(
        address superFormFactory_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superFormFactory_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldSuperFormFactory = protocolAddresses[SUPERFORM_FACTORY];
        protocolAddresses[SUPERFORM_FACTORY] = superFormFactory_;

        emit SuperFormFactoryUpdated(oldSuperFormFactory, superFormFactory_);
    }

    /// @inheritdoc ISuperRegistry
    function setCoreStateRegistry(
        address coreStateRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (coreStateRegistry_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldCoreStateRegistry = protocolAddresses[CORE_STATE_REGISTRY];
        protocolAddresses[CORE_STATE_REGISTRY] = coreStateRegistry_;

        emit CoreStateRegistryUpdated(oldCoreStateRegistry, coreStateRegistry_);
    }

    /// TODO: add to ISuperRegistry
    function setFormStateRegistry(
        address formStateRegistry_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (formStateRegistry_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldFormStateRegistry = protocolAddresses[FORM_STATE_REGISTRY];
        protocolAddresses[FORM_STATE_REGISTRY] = formStateRegistry_;

        emit CoreStateRegistryUpdated(oldFormStateRegistry, formStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    function setFactoryStateRegistry(
        address factoryStateRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (factoryStateRegistry_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldFactoryStateRegistry = protocolAddresses[
            FACTORY_STATE_REGISTRY
        ];
        protocolAddresses[FACTORY_STATE_REGISTRY] = factoryStateRegistry_;

        emit FactoryStateRegistryUpdated(
            oldFactoryStateRegistry,
            factoryStateRegistry_
        );
    }

    /// @inheritdoc ISuperRegistry
    function setSuperPositions(
        address superPositions_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superPositions_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldSuperPositions = protocolAddresses[SUPER_POSITIONS];
        protocolAddresses[SUPER_POSITIONS] = superPositions_;

        emit SuperPositionsUpdated(oldSuperPositions, superPositions_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperRBAC(
        address superRBAC_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superRBAC_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldSuperRBAC = protocolAddresses[SUPER_RBAC];
        protocolAddresses[SUPER_RBAC] = superRBAC_;

        emit SuperRBACUpdated(oldSuperRBAC, superRBAC_);
    }

    /// @inheritdoc ISuperRegistry
    function setMultiTxProcessor(
        address multiTxProcessor_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (multiTxProcessor_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldMultiTxProcessor = protocolAddresses[MULTI_TX_PROCESSOR];
        protocolAddresses[MULTI_TX_PROCESSOR] = multiTxProcessor_;

        emit MultiTxProcessorUpdated(oldMultiTxProcessor, multiTxProcessor_);
    }

    /// @inheritdoc ISuperRegistry
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            uint8 x = bridgeId_[i];
            address y = bridgeAddress_[i];
            address z = bridgeValidator_[i];
            if (y == address(0) || z == address(0)) revert Error.ZERO_ADDRESS();

            bridgeAddresses[x] = y;
            bridgeValidator[x] = z;

            emit SetBridgeAddress(x, y);
            emit SetBridgeValidator(x, z);
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
            if (x == address(0)) revert Error.ZERO_ADDRESS();

            ambAddresses[y] = x;
            emit SetAmbAddress(y, x);
        }
    }

    function setSuperPositionBank(
        address superPositionBank_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superPositionBank_ == address(0)) revert Error.ZERO_ADDRESS();

        address oldSuperPositionBank = protocolAddresses[SUPER_POSITION_BANK];
        protocolAddresses[SUPER_POSITION_BANK] = superPositionBank_;

        emit SetSuperPositionBankAddress(
            oldSuperPositionBank,
            superPositionBank_
        );
    }

    /*///////////////////////////////////////////////////////////////
                    External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function getProtocolAddress(
        bytes32 protocolAddressId_
    ) public view override returns (address) {
        return protocolAddresses[protocolAddressId_];
    }

    /// @inheritdoc ISuperRegistry
    function protocolAdmin()
        external
        view
        override
        returns (address protocolAdmin_)
    {
        protocolAdmin_ = getProtocolAddress(PROTOCOL_ADMIN);
    }

    /// @inheritdoc ISuperRegistry
    function superRouter()
        external
        view
        override
        returns (address superRouter_)
    {
        superRouter_ = getProtocolAddress(SUPER_ROUTER);
    }

    /// @inheritdoc ISuperRegistry
    function superFormFactory()
        external
        view
        override
        returns (address superFormFactory_)
    {
        superFormFactory_ = getProtocolAddress(SUPERFORM_FACTORY);
    }

    /// @inheritdoc ISuperRegistry
    function coreStateRegistry()
        external
        view
        override
        returns (address coreStateRegistry_)
    {
        coreStateRegistry_ = getProtocolAddress(CORE_STATE_REGISTRY);
    }

    /// TODO: inheritdoc ISuperRegistry
    function formStateRegistry()
        external
        view
        returns (address coreStateRegistry_)
    {
        coreStateRegistry_ = getProtocolAddress(FORM_STATE_REGISTRY);
    }


    /// @inheritdoc ISuperRegistry
    function factoryStateRegistry()
        external
        view
        override
        returns (address factoryStateRegistry_)
    {
        factoryStateRegistry_ = getProtocolAddress(FACTORY_STATE_REGISTRY);
    }

    /// @inheritdoc ISuperRegistry
    function superPositions()
        external
        view
        override
        returns (address superPositions_)
    {
        superPositions_ = getProtocolAddress(SUPER_POSITIONS);
    }

    function superPositionBank()
        external
        view
        returns (address superPositionBank_)
    {
        superPositionBank_ = getProtocolAddress(SUPER_POSITION_BANK);
    }

    /// @inheritdoc ISuperRegistry
    function superRBAC() external view override returns (address superRBAC_) {
        superRBAC_ = getProtocolAddress(SUPER_RBAC);
    }

    /// @inheritdoc ISuperRegistry
    function multiTxProcessor()
        external
        view
        override
        returns (address multiTxProcessor_)
    {
        multiTxProcessor_ = getProtocolAddress(MULTI_TX_PROCESSOR);
    }

    /// @inheritdoc ISuperRegistry
    function getBridgeAddress(
        uint8 bridgeId_
    ) external view override returns (address bridgeAddress_) {
        bridgeAddress_ = bridgeAddresses[bridgeId_];
    }

    /// @inheritdoc ISuperRegistry
    function getBridgeValidator(
        uint8 bridgeId_
    ) external view override returns (address bridgeValidator_) {
        bridgeValidator_ = bridgeValidator[bridgeId_];
    }

    /// @inheritdoc ISuperRegistry
    function getAmbAddress(
        uint8 ambId_
    ) external view override returns (address ambAddress_) {
        ambAddress_ = ambAddresses[ambId_];
    }
}
