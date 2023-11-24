// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ERC165Checker } from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { BaseForm } from "./BaseForm.sol";
import { BroadcastMessage } from "./types/DataTypes.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { IBroadcastRegistry } from "./interfaces/IBroadcastRegistry.sol";
import { ISuperRBAC } from "./interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "./interfaces/ISuperRegistry.sol";
import { Error } from "./libraries/Error.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { Clones } from "openzeppelin-contracts/contracts/proxy/Clones.sol";

/// @title Superforms Factory
/// @dev A secure, and easily queryable central point of access for all Superforms on any given chain,
/// @author Zeropoint Labs.
contract SuperformFactory is ISuperformFactory {
    using DataLib for uint256;
    using Clones for address;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////
    uint8 private constant NON_PAUSED = 1;
    uint8 private constant PAUSED = 2;

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    bytes32 constant SYNC_IMPLEMENTATION_STATUS = keccak256("SYNC_IMPLEMENTATION_STATUS");

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    uint256 public xChainPayloadCounter;
    uint256 public superformCounter;

    /// @dev all form beacon addresses
    address[] public formImplementations;

    /// @dev all superform ids
    uint256[] public superforms;
    mapping(uint256 superformId => bool superformIdExists) public isSuperform;

    /// @notice If formImplementationId is 0, formImplementation is not part of the protocol
    mapping(uint32 formImplementationId => address formBeaconAddress) public formImplementation;

    mapping(uint32 formImplementationId => PauseStatus) public formImplementationPaused;

    mapping(address vault => uint256[] superformIds) public vaultToSuperforms;

    mapping(address vault => uint256[] formImplementationId) public vaultToFormImplementationId;

    mapping(bytes32 vaultFormImplementationCombination => uint256 superformIds) public
        vaultFormImplCombinationToSuperforms;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

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

    modifier onlyBroadcastRegistry() {
        /// @dev this function is only accessible through broadcast registry
        if (msg.sender != superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))) {
            revert Error.NOT_BROADCAST_REGISTRY();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        CHAIN_ID = uint64(block.chainid);
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformFactory
    function getFormCount() external view override returns (uint256 forms_) {
        forms_ = formImplementations.length;
    }

    /// @inheritdoc ISuperformFactory
    function getSuperformCount() external view override returns (uint256 superforms_) {
        superforms_ = superforms.length;
    }

    /// @inheritdoc ISuperformFactory
    function getFormImplementation(uint32 formImplementationId_) external view override returns (address) {
        return formImplementation[formImplementationId_];
    }

    /// @inheritdoc ISuperformFactory
    function isFormImplementationPaused(uint32 formImplementationId_) external view override returns (bool) {
        return formImplementationPaused[formImplementationId_] == PauseStatus.PAUSED;
    }

    /// @inheritdoc ISuperformFactory
    function getSuperform(uint256 superformId_)
        external
        pure
        override
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_)
    {
        (superform_, formImplementationId_, chainId_) = superformId_.getSuperform();
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

        for (uint256 i; i < len; ++i) {
            (superforms_[i],,) = superformIds_[i].getSuperform();
        }
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

        for (uint256 i; i < len; ++i) {
            (superforms_[i],,) = superformIds_[i].getSuperform();
        }
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformFactory
    function addFormImplementation(
        address formImplementation_,
        uint32 formImplementationId_
    )
        public
        override
        onlyProtocolAdmin
    {
        if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(formImplementation_)) revert Error.ERC165_UNSUPPORTED();
        if (formImplementation[formImplementationId_] != address(0)) {
            revert Error.FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();
        }
        if (!ERC165Checker.supportsInterface(formImplementation_, type(IBaseForm).interfaceId)) {
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        }

        /// @dev save the newly added address in the mapping and array registry
        formImplementation[formImplementationId_] = formImplementation_;

        formImplementations.push(formImplementation_);

        emit FormImplementationAdded(formImplementation_, formImplementationId_);
    }

    /// @inheritdoc ISuperformFactory
    function createSuperform(
        uint32 formImplementationId_,
        address vault_
    )
        public
        override
        returns (uint256 superformId_, address superform_)
    {
        if (vault_ == address(0)) revert Error.ZERO_ADDRESS();

        address tFormImplementation = formImplementation[formImplementationId_];
        if (tFormImplementation == address(0)) revert Error.FORM_DOES_NOT_EXIST();

        /// @dev Same vault and beacon can be used only once to create superform
        bytes32 vaultFormImplementationCombination = keccak256(abi.encode(tFormImplementation, vault_));
        if (vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] != 0) {
            revert Error.VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();
        }

        /// @dev instantiate the superform
        superform_ =
            tFormImplementation.cloneDeterministic(keccak256(abi.encodePacked(uint256(CHAIN_ID), superformCounter)));
        ++superformCounter;

        BaseForm(payable(superform_)).initialize(address(superRegistry), vault_, address(IERC4626(vault_).asset()));

        /// @dev this will always be unique because all chainIds are unique
        superformId_ = DataLib.packSuperform(superform_, formImplementationId_, CHAIN_ID);

        vaultToSuperforms[vault_].push(superformId_);

        /// @dev Mapping vaults to formImplementationId for use in Backend
        vaultToFormImplementationId[vault_].push(formImplementationId_);

        vaultFormImplCombinationToSuperforms[vaultFormImplementationCombination] = superformId_;

        superforms.push(superformId_);
        isSuperform[superformId_] = true;

        emit SuperformCreated(formImplementationId_, vault_, superformId_, superform_);
    }

    /// @inheritdoc ISuperformFactory
    function changeFormImplementationPauseStatus(
        uint32 formImplementationId_,
        PauseStatus status_,
        bytes memory extraData_
    )
        external
        payable
        override
        onlyEmergencyAdmin
    {
        if (formImplementation[formImplementationId_] == address(0)) revert Error.INVALID_FORM_ID();
        formImplementationPaused[formImplementationId_] = status_;

        /// @dev broadcast the change in status to the other destination chains
        if (extraData_.length != 0) {
            BroadcastMessage memory factoryPayload = BroadcastMessage(
                "SUPERFORM_FACTORY",
                SYNC_IMPLEMENTATION_STATUS,
                abi.encode(CHAIN_ID, ++xChainPayloadCounter, formImplementationId_, status_)
            );

            _broadcast(abi.encode(factoryPayload), extraData_);
        }

        emit FormImplementationPaused(formImplementationId_, status_);
    }

    /// @inheritdoc ISuperformFactory
    function stateSyncBroadcast(bytes memory data_) external payable override onlyBroadcastRegistry {
        BroadcastMessage memory factoryPayload = abi.decode(data_, (BroadcastMessage));

        if (factoryPayload.messageType == SYNC_IMPLEMENTATION_STATUS) {
            _syncFormPausedStatus(factoryPayload.message);
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev interacts with broadcast state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8 ambId, bytes memory broadcastParams) = abi.decode(extraData_, (uint8, bytes));

        /// @dev ambIds are validated inside the broadcast state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBroadcastRegistry(superRegistry.getAddress(keccak256("BROADCAST_REGISTRY"))).broadcastPayload{
            value: msg.value
        }(msg.sender, ambId, message_, broadcastParams);
    }

    /// @dev synchronize paused status update message from remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncFormPausedStatus(bytes memory message_) internal {
        (,, uint32 formImplementationId, PauseStatus paused) =
            abi.decode(message_, (uint64, uint256, uint32, PauseStatus));

        if (formImplementation[formImplementationId] == address(0)) revert Error.INVALID_FORM_ID();
        formImplementationPaused[formImplementationId] = paused;

        emit FormImplementationPaused(formImplementationId, paused);
    }
}
