/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { QuorumManager } from "../crosschain-data/utils/QuorumManager.sol";
import { Error } from "../utils/Error.sol";

/// @title SuperRegistry
/// @author Zeropoint Labs.
/// @dev Keeps information on all addresses used in the Superforms ecosystem.
contract SuperRegistry is ISuperRegistry, QuorumManager {
    /// @dev chainId represents the superform chain id.
    uint64 public chainId;

    /// @dev canonical permit2 contract
    address public PERMIT2;

    mapping(bytes32 id => mapping(uint64 chainId => address moduleAddress)) private registry;
    /// @dev bridge id is mapped to a bridge address (to prevent interaction with unauthorized bridges)
    mapping(uint8 bridgeId => address bridgeAddress) public bridgeAddresses;
    mapping(uint8 bridgeId => address bridgeValidator) public bridgeValidator;
    mapping(uint8 bridgeId => address ambAddresses) public ambAddresses;
    mapping(uint8 registryId => address registryAddress) public registryAddresses;
    /// @dev is the reverse mapping of registryAddresses
    mapping(address registryAddress => uint8 registryId) public stateRegistryIds;
    /// @dev is the reverse mapping of ambAddresses
    mapping(address ambAddress => uint8 bridgeId) public ambIds;

    /// @dev core protocol - identifiers
    bytes32 public constant override SUPERFORM_ROUTER = keccak256("SUPERFORM_ROUTER");
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
    bytes32 public constant override PAYLOAD_HELPER = keccak256("PAYLOAD_HELPER");

    /// @dev default keepers - identifiers
    bytes32 public constant override PAYMENT_ADMIN = keccak256("PAYMENT_ADMIN");
    bytes32 public constant override MULTI_TX_SWAPPER = keccak256("MULTI_TX_SWAPPER");
    bytes32 public constant override CORE_REGISTRY_UPDATER = keccak256("CORE_REGISTRY_UPDATER");
    bytes32 public constant override CORE_REGISTRY_PROCESSOR = keccak256("CORE_REGISTRY_PROCESSOR");
    bytes32 public constant override FACTORY_REGISTRY_PROCESSOR = keccak256("FACTORY_REGISTRY_PROCESSOR");
    bytes32 public constant override ROLES_REGISTRY_PROCESSOR = keccak256("ROLES_REGISTRY_PROCESSOR");
    bytes32 public constant override TWO_STEPS_REGISTRY_PROCESSOR = keccak256("TWO_STEPS_REGISTRY_PROCESSOR");

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(registry[SUPER_RBAC][chainId]).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    constructor(address superRBAC_) {
        chainId = uint64(block.chainid);

        registry[SUPER_RBAC][chainId] = superRBAC_;

        emit SetChainId(chainId);

        emit AddressUpdated(SUPER_RBAC, chainId, address(0), superRBAC_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperRegistry
    function setPermit2(address permit2_) external override onlyProtocolAdmin {
        if (PERMIT2 != address(0)) revert Error.DISABLED();
        if (permit2_ == address(0)) revert Error.ZERO_ADDRESS();

        PERMIT2 = permit2_;

        emit SetPermit2(PERMIT2);
    }

    /// @inheritdoc ISuperRegistry
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external override onlyProtocolAdmin {
        address oldAddress = registry[id_][chainId_];
        registry[id_][chainId_] = newAddress_;
        emit AddressUpdated(id_, chainId_, oldAddress, newAddress_);
    }

    /// @inheritdoc ISuperRegistry
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    )
        external
        override
        onlyProtocolAdmin
    {
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
    function setAmbAddress(uint8[] memory ambId_, address[] memory ambAddress_) external override onlyProtocolAdmin {
        for (uint256 i; i < ambId_.length; i++) {
            address ambAddress = ambAddress_[i];
            uint8 ambId = ambId_[i];

            ambAddresses[ambId] = ambAddress;
            ambIds[ambAddress] = ambId;
            emit SetAmbAddress(ambId, ambAddress);
        }
    }

    /// @inheritdoc ISuperRegistry
    function setStateRegistryAddress(
        uint8[] memory registryId_,
        address[] memory registryAddress_
    )
        external
        override
        onlyProtocolAdmin
    {
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
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external override onlyProtocolAdmin {
        requiredQuorum[srcChainId_] = quorum_;

        emit QuorumSet(srcChainId_, quorum_);
    }

    /*///////////////////////////////////////////////////////////////
                    External View Functions
    //////////////////////////////////////////////////////////////*/

    function getAddress(bytes32 id_) external view override returns (address) {
        return registry[id_][chainId];
    }

    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view override returns (address) {
        return registry[id_][chainId_];
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
