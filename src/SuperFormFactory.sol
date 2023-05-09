///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import {BeaconProxy} from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {FormBeacon} from "./forms/FormBeacon.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {IBaseStateRegistry} from "./interfaces/IBaseStateRegistry.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {AMBFactoryMessage, AMBMessage} from "./types/DataTypes.sol";
import {BaseForm} from "./BaseForm.sol";
import {Error} from "./utils/Error.sol";
import "./utils/DataPacking.sol";

/// @title SuperForms Factory
/// @dev A secure, and easily queryable central point of access for all SuperForms on any given chain,
/// @author Zeropoint Labs.
contract SuperFormFactory is ISuperFormFactory {
    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_FORM_ID = 2 ** 80 - 1;
    bytes32 constant SYNC_NEW_SUPERFORM = keccak256("SYNC_NEW_SUPERFORM");
    bytes32 constant SYNC_BEACON_STATUS = keccak256("SYNC_BEACON_STATUS");

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    address[] public formBeacons;
    uint256[] public superForms;

    /// @notice If formBeaconId is 0, formBeacon is not part of the protocol
    mapping(uint256 formBeaconId => address formBeaconAddress)
        public formBeacon;

    mapping(address vault => uint256[] superFormIds) public vaultToSuperForms;

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
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
        uint256 formBeaconId_,
        bytes32 salt_
    ) public override onlyProtocolAdmin returns (address beacon) {
        if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(formImplementation_))
            revert Error.ERC165_UNSUPPORTED();
        if (
            !ERC165Checker.supportsInterface(
                formImplementation_,
                type(IBaseForm).interfaceId
            )
        ) revert Error.FORM_INTERFACE_UNSUPPORTED();
        if (formBeaconId_ > MAX_FORM_ID) revert Error.INVALID_FORM_ID();

        /// @dev TODO - created with create2. Should allow us to broadcast contract pauses and resumes cross chain
        beacon = address(
            new FormBeacon{salt: salt_}(
                address(superRegistry),
                formImplementation_
            )
        );

        /// @dev this should instantiate the beacon for each form
        formBeacon[formBeaconId_] = beacon;

        formBeacons.push(beacon);

        emit FormBeaconAdded(formImplementation_, beacon, formBeaconId_);
    }

    /// @inheritdoc ISuperFormFactory
    function addFormBeacons(
        address[] memory formImplementations_,
        uint256[] memory formBeaconIds_,
        bytes32 salt_
    ) external override onlyProtocolAdmin {
        for (uint256 i = 0; i < formImplementations_.length; i++) {
            addFormBeacon(formImplementations_[i], formBeaconIds_[i], salt_);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function createSuperForm(
        uint256 formBeaconId_, /// TimelockedBeaconId, NormalBeaconId... etc
        address vault_,
        bytes calldata extraData_
    )
        external
        payable
        override
        returns (uint256 superFormId_, address superForm_)
    {
        address tFormBeacon = formBeacon[formBeaconId_];
        if (vault_ == address(0)) revert Error.ZERO_ADDRESS();
        if (tFormBeacon == address(0)) revert Error.FORM_DOES_NOT_EXIST();
        if (formBeaconId_ > MAX_FORM_ID) revert Error.INVALID_FORM_ID();

        /// @dev TODO - should we predict superform address?
        /// @dev we just grab initialize selector from baseform, don't need to grab from a specific form
        superForm_ = address(
            new BeaconProxy(
                address(tFormBeacon),
                abi.encodeWithSelector(
                    BaseForm(payable(address(0))).initialize.selector,
                    superRegistry,
                    vault_
                )
            )
        );

        /// @dev this will always be unique because superForm is unique.
        superFormId_ = _packSuperForm(
            superForm_,
            formBeaconId_,
            superRegistry.chainId()
        );

        vaultToSuperForms[vault_].push(superFormId_);
        /// @dev FIXME do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(superFormId_);

        AMBFactoryMessage memory factoryPayload = AMBFactoryMessage(
            SYNC_NEW_SUPERFORM,
            abi.encode(superFormId_, vault_)
        );

        _broadcast(abi.encode(factoryPayload), extraData_);

        emit SuperFormCreated(formBeaconId_, vault_, superFormId_, superForm_);
    }

    /// @inheritdoc ISuperFormFactory
    function updateFormBeaconLogic(
        uint256 formBeaconId_,
        address newFormLogic_
    ) external override onlyProtocolAdmin {
        if (newFormLogic_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(newFormLogic_))
            revert Error.ERC165_UNSUPPORTED();
        if (
            !ERC165Checker.supportsInterface(
                newFormLogic_,
                type(IBaseForm).interfaceId
            )
        ) revert Error.FORM_INTERFACE_UNSUPPORTED();
        if (formBeacon[formBeaconId_] == address(0))
            revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).update(newFormLogic_);
    }

    /// @inheritdoc ISuperFormFactory
    function changeFormBeaconPauseStatus(
        uint256 formBeaconId_,
        bool status_,
        bytes memory extraData_
    ) external payable override onlyProtocolAdmin {
        if (formBeacon[formBeaconId_] == address(0))
            revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).changePauseStatus(status_);

        if (extraData_.length > 0) {
            AMBFactoryMessage memory factoryPayload = AMBFactoryMessage(
                SYNC_BEACON_STATUS,
                abi.encode(formBeaconId_, status_)
            );

            _broadcast(abi.encode(factoryPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function stateSync(bytes memory data_) external payable override {
        if (msg.sender != superRegistry.factoryStateRegistry())
            revert Error.NOT_FACTORY_STATE_REGISTRY();

        AMBMessage memory stateRegistryPayload = abi.decode(
            data_,
            (AMBMessage)
        );
        AMBFactoryMessage memory factoryPayload = abi.decode(
            stateRegistryPayload.params,
            (AMBFactoryMessage)
        );

        if (factoryPayload.messageType == SYNC_NEW_SUPERFORM) {
            _syncNewSuperform(factoryPayload.message);
        }

        if (factoryPayload.messageType == SYNC_BEACON_STATUS) {
            _syncBeaconStatus(factoryPayload.message);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the address of a form beacon
    /// @param formBeaconId_ is the id of the beacon form
    /// @return formBeacon_ is the address of the beacon form
    function getFormBeacon(
        uint256 formBeaconId_
    ) external view override returns (address formBeacon_) {
        formBeacon_ = formBeacon[formBeaconId_];
    }

    /// @dev returns the status of form beacon
    /// @param formBeaconId_ is the id of the beacon form
    /// @return status_ is the current status of the form beacon
    function getFormBeaconStatus(
        uint256 formBeaconId_
    ) external view override returns (bool status_) {
        status_ = FormBeacon(formBeacon[formBeaconId_]).paused();
    }

    /// @dev Reverse query of getSuperForm, returns all superforms for a given vault
    /// @param vault_ is the address of a vault
    /// @return superFormIds_ is the id of the superform
    /// @return formBeaconIds_ is the form id
    /// @return chainIds_ is the chain id
    function getAllSuperFormsFromVault(
        address vault_
    )
        external
        view
        override
        returns (
            uint256[] memory superFormIds_,
            uint256[] memory formBeaconIds_,
            uint16[] memory chainIds_
        )
    {
        superFormIds_ = vaultToSuperForms[vault_];
        uint256 len = superFormIds_.length;
        formBeaconIds_ = new uint256[](len);
        chainIds_ = new uint16[](len);

        for (uint256 i = 0; i < len; i++) {
            (, formBeaconIds_[i], chainIds_[i]) = _getSuperForm(
                superFormIds_[i]
            );
        }
    }

    /// @dev Returns all SuperForms
    /// @return superFormIds_ is the id of the superform
    /// @return superForms_ is the address of the vault
    /// @return formBeaconIds_ is the form beacon id
    /// @return chainIds_ is the chain id
    function getAllSuperForms()
        external
        view
        override
        returns (
            uint256[] memory superFormIds_,
            address[] memory superForms_,
            uint256[] memory formBeaconIds_,
            uint16[] memory chainIds_
        )
    {
        superFormIds_ = superForms;
        uint256 len = superFormIds_.length;
        superForms_ = new address[](len);
        formBeaconIds_ = new uint256[](len);
        chainIds_ = new uint16[](len);

        for (uint256 i = 0; i < len; i++) {
            (superForms_[i], formBeaconIds_[i], chainIds_[i]) = _getSuperForm(
                superFormIds_[i]
            );
        }
    }

    /// @dev returns the number of formbeacons
    /// @return forms_ is the number of formbeacons
    function getAllFormsList() external view override returns (uint256 forms_) {
        forms_ = formBeacons.length;
    }

    /// @dev returns the number of superforms
    /// @return superForms_ is the number of superforms
    function getAllSuperFormsList()
        external
        view
        override
        returns (uint256 superForms_)
    {
        superForms_ = superForms.length;
    }

    /// @dev returns the number of superforms for the given chain (where this call is made)
    function getAllChainSuperFormsList()
        external
        view
        override
        returns (uint256 superForms_)
    {
        uint256[] memory superFormIds_ = superForms;
        uint256 len = superFormIds_.length;

        uint16 chainIdRes;
        uint16 chainId = superRegistry.chainId();
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
    function _broadcast(
        bytes memory message_,
        bytes memory extraData_
    ) internal {
        (uint8[] memory ambIds, bytes memory broadcastParams) = abi.decode(
            extraData_,
            (uint8[], bytes)
        );

        /// @dev ambIds are validated inside the factory state registry
        /// @dev broadcastParams if wrong will revert in the amb implementation
        IBaseStateRegistry(superRegistry.factoryStateRegistry())
            .broadcastPayload{value: msg.value}(
            ambIds,
            message_,
            broadcastParams
        );
    }

    /// @dev synchornize new superform id created on a remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncNewSuperform(bytes memory message_) internal {
        (uint256 superFormId, address vaultAddress) = abi.decode(
            message_,
            (uint256, address)
        );
        /// FIXME: do we need extra checks before pushing here?
        vaultToSuperForms[vaultAddress].push(superFormId);

        /// @dev do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(superFormId);
    }

    /// @dev synchornize beacon status update message from remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncBeaconStatus(bytes memory message_) internal {
        (uint256 formBeaconId, bool status) = abi.decode(
            message_,
            (uint256, bool)
        );

        if (formBeacon[formBeaconId] == address(0))
            revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId]).changePauseStatus(status);
    }
}
