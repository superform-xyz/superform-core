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
                            State Variables
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_FORM_ID = 2 ** 80 - 1;

    /// @dev chainId represents the superform chain id.
    uint16 public immutable chainId;

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
    /// @param chainId_ the superform? chain id this factory is deployed on
    /// @param superRegistry_ the superform registry contract
    constructor(uint16 chainId_, address superRegistry_) {
        if (chainId_ == 0) revert Error.INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISuperFormFactory
    function addFormBeacon(
        address formImplementation_,
        uint256 formBeaconId_
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

        /// @dev TODO - should we predict beacon address?
        beacon = address(
            new FormBeacon(chainId, address(superRegistry), formImplementation_)
        );

        /// @dev this should instantiate the beacon for each form
        formBeacon[formBeaconId_] = beacon;

        formBeacons.push(beacon);

        emit FormBeaconAdded(formImplementation_, beacon, formBeaconId_);
    }

    /// @inheritdoc ISuperFormFactory
    function addFormBeacons(
        address[] memory formImplementations_,
        uint256[] memory formBeaconIds_
    ) external override onlyProtocolAdmin {
        for (uint256 i = 0; i < formImplementations_.length; i++) {
            addFormBeacon(formImplementations_[i], formBeaconIds_[i]);
        }
    }

    /// @inheritdoc ISuperFormFactory
    function createSuperForm(
        uint256 formBeaconId_, /// TimelockedBeaconId, NormalBeaconId... etc
        address vault_
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
                    chainId,
                    superRegistry,
                    vault_
                )
            )
        );

        /// @dev this will always be unique because superForm is unique.
        superFormId_ = _packSuperForm(superForm_, formBeaconId_, chainId);

        vaultToSuperForms[vault_].push(superFormId_);

        /// @dev FIXME do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(superFormId_);

        AMBFactoryMessage memory data = AMBFactoryMessage(superFormId_, vault_);

        /// @dev FIXME HARDCODED FIX AMBMESSAGE TO HAVE THIS AND THE PRIMARY AMBID
        uint8[] memory ambIds = new uint8[](2);
        ambIds[0] = 2;
        ambIds[1] = 1;

        IBaseStateRegistry(superRegistry.factoryStateRegistry())
            .broadcastPayload{value: msg.value}(ambIds, abi.encode(data), "");

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
        bool status_
    ) external override onlyProtocolAdmin {
        if (formBeacon[formBeaconId_] == address(0))
            revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).changePauseStatus(status_);
    }

    /// @inheritdoc ISuperFormFactory
    function stateSync(bytes memory data_) external payable override {
        if (msg.sender != superRegistry.factoryStateRegistry())
            revert Error.NOT_FACTORY_STATE_REGISTRY();

        AMBMessage memory message = abi.decode(data_, (AMBMessage));

        AMBFactoryMessage memory data = abi.decode(
            message.params,
            (AMBFactoryMessage)
        );

        /// @dev TODO - do we need extra checks before pushing here?

        vaultToSuperForms[data.vaultAddress].push(data.superFormId);

        /// @dev do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(data.superFormId);
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
        for (uint256 i = 0; i < len; i++) {
            (, , chainIdRes) = _getSuperForm(superFormIds_[i]);
            if (chainIdRes == chainId) {
                unchecked {
                    ++superForms_;
                }
            }
        }
    }
}
