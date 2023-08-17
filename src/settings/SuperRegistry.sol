/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {QuorumManager} from "../crosschain-data/utils/QuorumManager.sol";
import {Error} from "../utils/Error.sol";

/// @title SuperRegistry
/// @author Zeropoint Labs.
/// @dev Keeps information on all protocolAddresses used in the Superforms ecosystem.
contract SuperRegistry is ISuperRegistry, QuorumManager {
    /// @dev chainId represents the superform chain id.
    uint64 public chainId;

    /// @dev canonical permit2 contract
    address public PERMIT2;

    mapping(bytes32 id => address moduleAddress) private protocolAddresses;
    mapping(bytes32 id => mapping(uint64 chainId => address moduleAddress)) private crossChainRegistry;
    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 bridgeId => address bridgeAddress) public bridgeAddresses;
    mapping(uint8 bridgeId => address bridgeValidator) public bridgeValidator;
    mapping(uint8 bridgeId => address ambAddresses) public ambAddresses;
    mapping(uint8 registryId => address registryAddress) public registryAddresses;
    /// @dev is the reverse mapping of registryAddresses
    mapping(address registryAddress => uint8 registryId) public stateRegistryIds;
    /// @dev is the reverse mapping of ambAddresses
    mapping(address ambAddress => uint8 bridgeId) public ambIds;

    /// @dev core protocol addresses identifiers
    bytes32 public constant override SUPER_ROUTER = keccak256("SUPER_ROUTER");
    bytes32 public constant override SUPERFORM_FACTORY = keccak256("SUPERFORM_FACTORY");
    bytes32 public constant override PAYMASTER = keccak256("PAYMASTER");
    bytes32 public constant override PAYMENT_HELPER = keccak256("PAYMENT_HELPER");
    bytes32 public constant override CORE_STATE_REGISTRY = keccak256("CORE_STATE_REGISTRY");
    bytes32 public constant override TWO_STEPS_FORM_STATE_REGISTRY = keccak256("TWO_STEPS_FORM_STATE_REGISTRY");
    bytes32 public constant override FACTORY_STATE_REGISTRY = keccak256("FACTORY_STATE_REGISTRY");
    bytes32 public constant override ROLES_STATE_REGISTRY = keccak256("ROLES_STATE_REGISTRY");
    bytes32 public constant override SUPER_POSITIONS = keccak256("SUPER_POSITIONS");
    bytes32 public constant override SUPER_RBAC = keccak256("SUPER_RBAC");
    bytes32 public constant override MULTI_TX_PROCESSOR = keccak256("MULTI_TX_PROCESSOR");
    bytes32 public constant override TX_PROCESSOR = keccak256("TX_PROCESSOR");
    bytes32 public constant override TX_UPDATER = keccak256("TX_UPDATER");

    modifier onlyCaller() {
        if (!ISuperRBAC(protocolAddresses[SUPER_RBAC]).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    constructor(address superRBAC_) {
        crossChainRegistry[SUPER_RBAC][chainId] = superRBAC_;

        emit AddressUpdated(SUPER_RBAC, chainId, address(0), superRBAC_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function setImmutables(uint64 chainId_, address permit2_) external override onlyCaller {
        if (chainId != 0 || PERMIT2 != address(0)) revert Error.DISABLED();
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();
        if (permit2_ == address(0)) revert Error.ZERO_ADDRESS();
        chainId = chainId_;
        PERMIT2 = permit2_;

        emit SetImmutables(chainId_, PERMIT2);
    }

    /// @inheritdoc ISuperRegistry
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external override onlyCaller {
        address oldAddress = crossChainRegistry[id_][chainId_];
        crossChainRegistry[id_][chainId_] = newAddress_;
        emit AddressUpdated(id_, chainId_, oldAddress, newAddress_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperRouter(address superformRouter_) external override onlyCaller {
        address oldSuperRouter = protocolAddresses[SUPER_ROUTER];
        protocolAddresses[SUPER_ROUTER] = superformRouter_;

        emit SuperRouterUpdated(oldSuperRouter, superformRouter_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperformFactory(address superformFactory_) external override onlyCaller {
        address oldSuperformFactory = protocolAddresses[SUPERFORM_FACTORY];
        protocolAddresses[SUPERFORM_FACTORY] = superformFactory_;

        emit SuperformFactoryUpdated(oldSuperformFactory, superformFactory_);
    }

    /// @inheritdoc ISuperRegistry
    function setPayMaster(address feeCollector_) external override onlyCaller {
        address oldPayMaster = protocolAddresses[PAYMASTER];
        protocolAddresses[PAYMASTER] = feeCollector_;

        emit PayMasterUpdated(oldPayMaster, feeCollector_);
    }

    /// @inheritdoc ISuperRegistry
    function setPaymentHelper(address paymentHelper_) external override onlyCaller {
        address oldPaymentHelper = protocolAddresses[PAYMENT_HELPER];
        protocolAddresses[PAYMENT_HELPER] = paymentHelper_;

        emit PaymentHelperUpdated(oldPaymentHelper, paymentHelper_);
    }

    /// @inheritdoc ISuperRegistry
    function setCoreStateRegistry(address coreStateRegistry_) external override onlyCaller {
        address oldCoreStateRegistry = protocolAddresses[CORE_STATE_REGISTRY];
        protocolAddresses[CORE_STATE_REGISTRY] = coreStateRegistry_;

        emit CoreStateRegistryUpdated(oldCoreStateRegistry, coreStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    function setCoreStateRegistryCrossChain(address coreStateRegistry_, uint64 chainId_) external override onlyCaller {
        address oldCoreStateRegistry = crossChainRegistry[CORE_STATE_REGISTRY][chainId_];
        crossChainRegistry[CORE_STATE_REGISTRY][chainId_] = coreStateRegistry_;

        emit CoreStateRegistryCrossChainUpdated(chainId_, oldCoreStateRegistry, coreStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    function setTwoStepsFormStateRegistry(address twoStepsFormStateRegistry_) external onlyCaller {
        address oldTwoStepsFormStateRegistry = protocolAddresses[TWO_STEPS_FORM_STATE_REGISTRY];
        protocolAddresses[TWO_STEPS_FORM_STATE_REGISTRY] = twoStepsFormStateRegistry_;

        emit TwoStepsFormStateRegistryUpdated(oldTwoStepsFormStateRegistry, twoStepsFormStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    function setFactoryStateRegistry(address factoryStateRegistry_) external override onlyCaller {
        address oldFactoryStateRegistry = protocolAddresses[FACTORY_STATE_REGISTRY];
        protocolAddresses[FACTORY_STATE_REGISTRY] = factoryStateRegistry_;

        emit FactoryStateRegistryUpdated(oldFactoryStateRegistry, factoryStateRegistry_);
    }

    /// @inheritdoc ISuperRegistry
    /*
    function setRolesStateRegistry(address rolesStateRegistry_) external override onlyCaller {
        address oldRolesStateRegistry = protocolAddresses[ROLES_STATE_REGISTRY];
        protocolAddresses[ROLES_STATE_REGISTRY] = rolesStateRegistry_;

        emit RolesStateRegistryUpdated(oldRolesStateRegistry, rolesStateRegistry_);
    }
    */

    /// @inheritdoc ISuperRegistry
    function setSuperPositions(address superPositions_) external override onlyCaller {
        address oldSuperPositions = protocolAddresses[SUPER_POSITIONS];
        protocolAddresses[SUPER_POSITIONS] = superPositions_;

        emit SuperPositionsUpdated(oldSuperPositions, superPositions_);
    }

    /// @inheritdoc ISuperRegistry
    function setSuperRBAC(address superRBAC_) public override onlyCaller {
        address oldSuperRBAC = protocolAddresses[SUPER_RBAC];
        protocolAddresses[SUPER_RBAC] = superRBAC_;

        emit SuperRBACUpdated(oldSuperRBAC, superRBAC_);
    }

    /// @inheritdoc ISuperRegistry
    function setMultiTxProcessor(address multiTxProcessor_) external override onlyCaller {
        address oldMultiTxProcessor = protocolAddresses[MULTI_TX_PROCESSOR];
        protocolAddresses[MULTI_TX_PROCESSOR] = multiTxProcessor_;

        emit MultiTxProcessorUpdated(oldMultiTxProcessor, multiTxProcessor_);
    }

    /// @inheritdoc ISuperRegistry
    function setMultiTxProcessorCrossChain(address multiTxProcessor_, uint64 chainId_) external override onlyCaller {
        address oldMultiTxProcessor = crossChainRegistry[MULTI_TX_PROCESSOR][chainId_];
        crossChainRegistry[MULTI_TX_PROCESSOR][chainId_] = multiTxProcessor_;

        emit MultiTxProcessorCrossChainUpdated(chainId_, oldMultiTxProcessor, multiTxProcessor_);
    }

    /// @inheritdoc ISuperRegistry
    function setTxProcessor(address txProcessor_) external override onlyCaller {
        address oldTxProcessor = protocolAddresses[TX_PROCESSOR];
        protocolAddresses[TX_PROCESSOR] = txProcessor_;

        emit TxProcessorUpdated(oldTxProcessor, txProcessor_);
    }

    /// @inheritdoc ISuperRegistry
    function setTxUpdater(address txUpdater_) external override onlyCaller {
        address oldTxUpdater = protocolAddresses[TX_UPDATER];
        protocolAddresses[TX_UPDATER] = txUpdater_;

        emit TxProcessorUpdated(oldTxUpdater, txUpdater_);
    }

    /// @inheritdoc ISuperRegistry
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    ) external override onlyCaller {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            uint8 bridgeId = bridgeId_[i];
            address bridgeAddress = bridgeAddress_[i];
            address bridgeValidatorT = bridgeValidator_[i];

            bridgeAddresses[bridgeId] = bridgeAddress;
            bridgeValidator[bridgeId] = bridgeValidatorT;
            emit SetBridgeAddress(bridgeId, bridgeAddress);
            emit SetBridgeValidator(bridgeId, bridgeValidatorT);
        }
    }

    /// @inheritdoc ISuperRegistry
    function setAmbAddress(uint8[] memory ambId_, address[] memory ambAddress_) external override onlyCaller {
        for (uint256 i; i < ambId_.length; i++) {
            address ambAddress = ambAddress_[i];
            uint8 ambId = ambId_[i];
            if (ambAddress == address(0)) revert Error.ZERO_ADDRESS();

            ambAddresses[ambId] = ambAddress;
            ambIds[ambAddress] = ambId;
            emit SetAmbAddress(ambId, ambAddress);
        }
    }

    /// @inheritdoc ISuperRegistry
    function setStateRegistryAddress(
        uint8[] memory registryId_,
        address[] memory registryAddress_
    ) external override onlyCaller {
        for (uint256 i; i < registryId_.length; i++) {
            address registryAddress = registryAddress_[i];
            uint8 registryId = registryId_[i];
            if (registryAddress == address(0)) revert Error.ZERO_ADDRESS();

            registryAddresses[registryId] = registryAddress;
            stateRegistryIds[registryAddress] = registryId;
            emit SetStateRegistryAddress(registryId, registryAddress);
        }
    }

    /// @inheritdoc QuorumManager
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external override onlyCaller {
        requiredQuorum[srcChainId_] = quorum_;
    }

    /*///////////////////////////////////////////////////////////////
                    External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function getProtocolAddress(bytes32 protocolAddressId_) public view override returns (address) {
        return protocolAddresses[protocolAddressId_];
    }

    function getAddress(bytes32 id_) external view override returns (address) {
        return crossChainRegistry[id_][chainId];
    }

    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view override returns (address) {
        return crossChainRegistry[id_][chainId_];
    }

    /// @inheritdoc ISuperRegistry
    function getBridgeAddress(uint8 bridgeId_) external view override returns (address bridgeAddress_) {
        bridgeAddress_ = bridgeAddresses[bridgeId_];
    }

    /// @inheritdoc ISuperRegistry
    function getBridgeValidator(uint8 bridgeId_) external view override returns (address bridgeValidator_) {
        bridgeValidator_ = bridgeValidator[bridgeId_];
    }

    /// @inheritdoc ISuperRegistry
    function getAmbAddress(uint8 ambId_) external view override returns (address ambAddress_) {
        ambAddress_ = ambAddresses[ambId_];
    }

    /// @inheritdoc ISuperRegistry
    function getStateRegistry(uint8 registryId_) external view override returns (address registryAddress_) {
        registryAddress_ = registryAddresses[registryId_];
    }

    /// @inheritdoc ISuperRegistry
    function getStateRegistryId(address registryAddress_) external view override returns (uint8 registryId_) {
        registryId_ = stateRegistryIds[registryAddress_];
    }

    /// @inheritdoc ISuperRegistry
    function isValidStateRegistry(address registryAddress_) external view override returns (bool valid_) {
        if (stateRegistryIds[registryAddress_] != 0) return true;

        return false;
    }

    /// @inheritdoc ISuperRegistry
    function isValidAmbImpl(address ambAddress_) external view override returns (bool valid_) {
        if (ambIds[ambAddress_] != 0) return true;

        return false;
    }
}
