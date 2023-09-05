///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import { BaseForm } from "./BaseForm.sol";
import { FormBeacon } from "./forms/FormBeacon.sol";
import { BroadcastMessage } from "./types/DataTypes.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";
import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { Error } from "./utils/Error.sol";
import { DataLib } from "./libraries/DataLib.sol";

/// @title Superforms Factory
/// @dev A secure, and easily queryable central point of access for all Superforms on any given chain,
/// @author Zeropoint Labs.
contract SuperformFactory is ISuperformFactory {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    bytes32 constant SYNC_BEACON_STATUS = keccak256("SYNC_BEACON_STATUS");

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    uint256 public xChainPayloadCounter;
    ISuperRegistry public immutable superRegistry;

    /// @dev all form beacon addresses
    address[] public formBeacons;

    /// @dev all superform ids
    uint256[] public superforms;

    /// @notice If formBeaconId is 0, formBeacon is not part of the protocol
    mapping(uint32 formBeaconId => address formBeaconAddress) public formBeacon;

    mapping(address vault => uint256[] superformIds) public vaultToSuperforms;

    mapping(address vault => uint256[] formBeaconId) public vaultToFormBeaconId;

    mapping(bytes32 vaultBeaconCombination => uint256 superformIds) public vaultBeaconToSuperforms;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
        }
        _;
    }

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasProtocolAdminRole(msg.sender)) {
            revert Error.NOT_PROTOCOL_ADMIN();
        }
        _;
    }

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperformFactory
    function addFormBeacon(
        address formImplementation_,
        uint32 formBeaconId_,
        bytes32 salt_
    )
        public
        override
        onlyProtocolAdmin
        returns (address beacon)
    {
        if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(formImplementation_)) revert Error.ERC165_UNSUPPORTED();
        if (formBeacon[formBeaconId_] != address(0)) revert Error.BEACON_ID_ALREADY_EXISTS();
        if (!ERC165Checker.supportsInterface(formImplementation_, type(IBaseForm).interfaceId)) {
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        }

        /// @dev instantiate a new formBeacon using a given formImplementation
        beacon = address(new FormBeacon{salt: salt_}(address(superRegistry), formImplementation_));

        /// @dev save the newly created beacon address in the mapping and array registry
        formBeacon[formBeaconId_] = beacon;

        formBeacons.push(beacon);

        emit FormBeaconAdded(formImplementation_, beacon, formBeaconId_);
    }

    /// @inheritdoc ISuperformFactory
    function createSuperform(
        uint32 formBeaconId_,
        address vault_
    )
        public
        override
        returns (uint256 superformId_, address superform_)
    {
        address tFormBeacon = formBeacon[formBeaconId_];
        if (vault_ == address(0)) revert Error.ZERO_ADDRESS();
        if (tFormBeacon == address(0)) revert Error.FORM_DOES_NOT_EXIST();

        /// @dev Same vault and beacon can be used only once to create superform
        bytes32 vaultBeaconCombination = keccak256(abi.encode(tFormBeacon, vault_));
        if (vaultBeaconToSuperforms[vaultBeaconCombination] != 0) revert Error.VAULT_BEACON_COMBNATION_EXISTS();

        /// @dev instantiate the superform. The initialize function call is encoded in the request
        superform_ = address(
            new BeaconProxy(
                address(tFormBeacon),
                abi.encodeWithSelector(BaseForm(payable(address(0))).initialize.selector, superRegistry, vault_)
            )
        );

        /// @dev this will always be unique because all chainIds are unique
        superformId_ = DataLib.packSuperform(superform_, formBeaconId_, superRegistry.chainId());

        vaultToSuperforms[vault_].push(superformId_);

        /// @dev Mapping vaults to formBeaconId for use in Backend
        vaultToFormBeaconId[vault_].push(formBeaconId_);

        vaultBeaconToSuperforms[vaultBeaconCombination] = superformId_;

        superforms.push(superformId_);

        emit SuperformCreated(formBeaconId_, vault_, superformId_, superform_);
    }

    /// @inheritdoc ISuperformFactory
    function createSuperforms(
        uint32[] memory formBeaconIds_,
        address[] memory vaults_
    )
        external
        override
        returns (uint256[] memory superformIds_, address[] memory superforms_)
    {
        uint256 len = formBeaconIds_.length;

        if (len != vaults_.length) revert Error.ARRAY_LENGTH_MISMATCH();

        superformIds_ = new uint256[](len);
        superforms_ = new address[](len);

        for (uint256 i; i < len;) {
            (superformIds_[i], superforms_[i]) = createSuperform(formBeaconIds_[i], vaults_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISuperformFactory
    function updateFormBeaconLogic(uint32 formBeaconId_, address newFormLogic_) external override onlyProtocolAdmin {
        if (newFormLogic_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(newFormLogic_)) revert Error.ERC165_UNSUPPORTED();
        if (!ERC165Checker.supportsInterface(newFormLogic_, type(IBaseForm).interfaceId)) {
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        }
        if (formBeacon[formBeaconId_] == address(0)) revert Error.INVALID_FORM_ID();

        /// @dev form logics are not updated via broadcasting
        FormBeacon(formBeacon[formBeaconId_]).update(newFormLogic_);
    }

    /// @inheritdoc ISuperformFactory
    function changeFormBeaconPauseStatus(
        uint32 formBeaconId_,
        uint256 paused_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlyEmergencyAdmin
    {
        if (formBeacon[formBeaconId_] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).changePauseStatus(paused_);

        /// @dev broadcast the change in status to the other destination chains
        if (extraData_.length > 0) {
            BroadcastMessage memory factoryPayload = BroadcastMessage(
                "SUPERFORM_FACTORY",
                SYNC_BEACON_STATUS,
                abi.encode(superRegistry.chainId(), ++xChainPayloadCounter, formBeaconId_, paused_)
            );

            _broadcast(abi.encode(factoryPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperformFactory
    function stateSyncBroadcast(bytes memory data_) external payable override {
        /// @dev this function is only accessible through broadcast registry
        if (msg.sender != superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))) {
            revert Error.NOT_BROADCAST_REGISTRY();
        }

        BroadcastMessage memory factoryPayload = abi.decode(data_, (BroadcastMessage));

        if (factoryPayload.messageType == SYNC_BEACON_STATUS) {
            _syncBeaconStatus(factoryPayload.message);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperformFactory
    function getFormBeacon(uint32 formBeaconId_) external view override returns (address formBeacon_) {
        formBeacon_ = formBeacon[formBeaconId_];
    }

    /// @inheritdoc ISuperformFactory
    function isFormBeaconPaused(uint32 formBeaconId_) external view override returns (uint256 paused_) {
        paused_ = FormBeacon(formBeacon[formBeaconId_]).paused();
    }

    /// @inheritdoc ISuperformFactory
    function getAllSuperformsFromVault(address vault_)
        external
        view
        override
        returns (uint256[] memory superformIds_, address[] memory superforms_)
    {
        superformIds_ = vaultToSuperforms[vault_];
        uint256 len = superformIds_.length;
        superforms_ = new address[](len);

        for (uint256 i; i < len;) {
            (superforms_[i],,) = superformIds_[i].getSuperform();

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISuperformFactory
    function getSuperform(uint256 superformId)
        external
        pure
        override
        returns (address superform_, uint32 formBeaconId_, uint64 chainId_)
    {
        (superform_, formBeaconId_, chainId_) = superformId.getSuperform();
    }

    /// @inheritdoc ISuperformFactory
    function getAllSuperforms()
        external
        view
        override
        returns (uint256[] memory superformIds_, address[] memory superforms_)
    {
        superformIds_ = superforms;
        uint256 len = superformIds_.length;
        superforms_ = new address[](len);

        for (uint256 i; i < len;) {
            (superforms_[i],,) = superformIds_[i].getSuperform();
            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISuperformFactory
    function getFormCount() external view override returns (uint256 forms_) {
        forms_ = formBeacons.length;
    }

    /// @inheritdoc ISuperformFactory
    function getSuperformCount() external view override returns (uint256 superforms_) {
        superforms_ = superforms.length;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev interacts with broadcast state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(extraData_, (uint8[], bytes));

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambIds, message_, broadcastParams);
    }

    /// @dev synchornize beacon status update message from remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncBeaconStatus(bytes memory message_) internal {
        (,, uint32 formBeaconId, uint256 status) = abi.decode(message_, (uint64, uint256, uint32, uint256));

        if (formBeacon[formBeaconId] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId]).changePauseStatus(status);
    }

    function getBytecodeFormBeacon(address superRegistry_, address formLogic_) public pure returns (bytes memory) {
        bytes memory bytecode = type(FormBeacon).creationCode;

        return abi.encodePacked(bytecode, abi.encode(superRegistry_, formLogic_));
    }
}
