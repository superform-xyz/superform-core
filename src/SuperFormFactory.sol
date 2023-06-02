///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import {BeaconProxy} from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {BaseForm} from "./BaseForm.sol";
import {FormBeacon} from "./forms/FormBeacon.sol";
import {AMBFactoryMessage, AMBMessage} from "./types/DataTypes.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {IBaseStateRegistry} from "./interfaces/IBaseStateRegistry.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {Error} from "./utils/Error.sol";
import "./utils/DataPacking.sol";

/// @title SuperForms Factory
/// @dev A secure, and easily queryable central point of access for all SuperForms on any given chain,
/// @author Zeropoint Labs.
contract SuperFormFactory is ISuperFormFactory {
    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_FORM_ID = 2 ** 32 - 1;
    bytes32 constant SYNC_BEACON_STATUS = keccak256("SYNC_BEACON_STATUS");

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    address[] public formBeacons;
    uint256[] public superForms;

    /// @notice If formBeaconId is 0, formBeacon is not part of the protocol
    mapping(uint32 formBeaconId => address formBeaconAddress) public formBeacon;

    mapping(address vault => uint256[] superFormIds) public vaultToSuperForms;

    mapping(address vault => uint256 formBeaconId) public vaultToFormBeaconId;

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    /// @dev sets caller as the admin of the contract.
    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperFormFactory
    function addFormBeacon(
        address formImplementation_,
        uint32 formBeaconId_,
        bytes32 salt_
    ) public override onlyProtocolAdmin returns (address beacon) {
        if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(formImplementation_)) revert Error.ERC165_UNSUPPORTED();
        if (!ERC165Checker.supportsInterface(formImplementation_, type(IBaseForm).interfaceId))
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        if (formBeaconId_ > MAX_FORM_ID) revert Error.INVALID_FORM_ID();

        beacon = address(new FormBeacon{salt: salt_}(address(superRegistry), formImplementation_));

        /// @dev this should instantiate the beacon for each form
        formBeacon[formBeaconId_] = beacon;

        formBeacons.push(beacon);

        emit FormBeaconAdded(formImplementation_, beacon, formBeaconId_);
    }

    /// @inheritdoc ISuperFormFactory
    function addFormBeacons(
        address[] memory formImplementations_,
        uint32[] memory formBeaconIds_,
        bytes32 salt_
    ) external override onlyProtocolAdmin {
        for (uint256 i = 0; i < formImplementations_.length; i++) {
            addFormBeacon(formImplementations_[i], formBeaconIds_[i], salt_);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function createSuperForm(
        uint32 formBeaconId_, /// TimelockedBeaconId, NormalBeaconId... etc
        address vault_
    ) external override returns (uint256 superFormId_, address superForm_) {
        address tFormBeacon = formBeacon[formBeaconId_];
        if (vault_ == address(0)) revert Error.ZERO_ADDRESS();
        if (vaultToFormBeaconId[vault_] != 0) revert Error.VAULT_ALREADY_HAS_FORM();
        if (tFormBeacon == address(0)) revert Error.FORM_DOES_NOT_EXIST();
        if (formBeaconId_ > MAX_FORM_ID) revert Error.INVALID_FORM_ID();

        /// @dev TODO - should we predict superform address?
        superForm_ = address(
            new BeaconProxy(
                address(tFormBeacon),
                abi.encodeWithSelector(BaseForm(payable(address(0))).initialize.selector, superRegistry, vault_)
            )
        );

        /// @dev this will always be unique because superForm is unique.
        superFormId_ = _packSuperForm(superForm_, formBeaconId_, superRegistry.chainId());

        vaultToSuperForms[vault_].push(superFormId_);
        /// @dev FIXME do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(superFormId_);
        vaultToFormBeaconId[vault_] = formBeaconId_;

        emit SuperFormCreated(formBeaconId_, vault_, superFormId_, superForm_);
    }

    /// @inheritdoc ISuperFormFactory
    function updateFormBeaconLogic(uint32 formBeaconId_, address newFormLogic_) external override onlyProtocolAdmin {
        if (newFormLogic_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(newFormLogic_)) revert Error.ERC165_UNSUPPORTED();
        if (!ERC165Checker.supportsInterface(newFormLogic_, type(IBaseForm).interfaceId))
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        if (formBeacon[formBeaconId_] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).update(newFormLogic_);
    }

    /// @inheritdoc ISuperFormFactory
    function changeFormBeaconPauseStatus(
        uint32 formBeaconId_,
        bool paused_,
        bytes memory extraData_
    ) external payable override onlyProtocolAdmin {
        if (formBeacon[formBeaconId_] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).changePauseStatus(paused_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory factoryPayload = AMBFactoryMessage(
                SYNC_BEACON_STATUS,
                abi.encode(formBeaconId_, paused_)
            );

            _broadcast(abi.encode(factoryPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function stateSync(bytes memory data_) external payable override {
        if (msg.sender != superRegistry.factoryStateRegistry()) revert Error.NOT_FACTORY_STATE_REGISTRY();

        AMBMessage memory stateRegistryPayload = abi.decode(data_, (AMBMessage));
        AMBFactoryMessage memory factoryPayload = abi.decode(stateRegistryPayload.params, (AMBFactoryMessage));

        if (factoryPayload.messageType == SYNC_BEACON_STATUS) {
            _syncBeaconStatus(factoryPayload.message);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperFormFactory
    function getFormBeacon(uint32 formBeaconId_) external view override returns (address formBeacon_) {
        formBeacon_ = formBeacon[formBeaconId_];
    }

    /// @inheritdoc ISuperFormFactory
    function isFormBeaconPaused(uint32 formBeaconId_) external view override returns (bool paused_) {
        paused_ = FormBeacon(formBeacon[formBeaconId_]).paused();
    }

    /// @inheritdoc ISuperFormFactory
    function getAllSuperFormsFromVault(
        address vault_
    )
        external
        view
        override
        returns (
            uint256[] memory superFormIds_,
            address[] memory superForms_,
            uint32[] memory formBeaconIds_,
            uint64[] memory chainIds_
        )
    {
        superFormIds_ = vaultToSuperForms[vault_];
        uint256 len = superFormIds_.length;
        superForms_ = new address[](len);
        formBeaconIds_ = new uint32[](len);
        chainIds_ = new uint64[](len);

        for (uint256 i = 0; i < len; i++) {
            (superForms_[i], formBeaconIds_[i], chainIds_[i]) = _getSuperForm(superFormIds_[i]);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function getSuperForm(
        uint256 superFormId
    ) external pure override returns (address superForm_, uint32 formBeaconId_, uint64 chainId_) {
        (superForm_, formBeaconId_, chainId_) = _getSuperForm(superFormId);
    }

    /// @inheritdoc ISuperFormFactory
    function getAllSuperForms()
        external
        view
        override
        returns (
            uint256[] memory superFormIds_,
            address[] memory superForms_,
            uint32[] memory formBeaconIds_,
            uint64[] memory chainIds_
        )
    {
        superFormIds_ = superForms;
        uint256 len = superFormIds_.length;
        superForms_ = new address[](len);
        formBeaconIds_ = new uint32[](len);
        chainIds_ = new uint64[](len);

        for (uint256 i = 0; i < len; i++) {
            (superForms_[i], formBeaconIds_[i], chainIds_[i]) = _getSuperForm(superFormIds_[i]);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function getAllFormsList() external view override returns (uint256 forms_) {
        forms_ = formBeacons.length;
    }

    /// @inheritdoc ISuperFormFactory
    function getAllSuperFormsList() external view override returns (uint256 superForms_) {
        superForms_ = superForms.length;
    }

    /// @inheritdoc ISuperFormFactory
    function getAllChainSuperFormsList() external view override returns (uint256 superForms_) {
        uint256[] memory superFormIds_ = superForms;
        uint256 len = superFormIds_.length;

        uint64 chainIdRes;
        uint64 chainId = superRegistry.chainId();
        for (uint256 i = 0; i < len; i++) {
            (, , chainIdRes) = _getSuperForm(superFormIds_[i]);
            if (chainIdRes == chainId) {
                unchecked {
                    ++superForms_;
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev interacts with factory state registry to broadcasting state changes to all connected remote chains
    /// @param message_ is the crosschain message to be sent.
    /// @param extraData_ is the amb override information.
    function _broadcast(bytes memory message_, bytes memory extraData_) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(extraData_, (uint8[], bytes));

        /// @dev ambIds are validated inside the factory state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBaseStateRegistry(superRegistry.factoryStateRegistry()).broadcastPayload{value: msg.value}(
            msg.sender,
            ambIds,
            message_,
            broadcastParams
        );
    }

    /// @dev synchornize new superform id created on a remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncNewSuperform(bytes memory message_) internal {
        (uint256 superFormId, address vaultAddress) = abi.decode(message_, (uint256, address));
        /// FIXME: do we need extra checks before pushing here?
        vaultToSuperForms[vaultAddress].push(superFormId);

        /// @dev do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(superFormId);
    }

    /// @dev synchornize beacon status update message from remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncBeaconStatus(bytes memory message_) internal {
        (uint32 formBeaconId, bool status) = abi.decode(message_, (uint32, bool));

        if (formBeacon[formBeaconId] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId]).changePauseStatus(status);
    }
}
