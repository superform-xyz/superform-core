///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ERC165Checker} from "openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import {BeaconProxy} from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {BaseForm} from "./BaseForm.sol";
import {FormBeacon} from "./forms/FormBeacon.sol";
import {AMBFactoryMessage} from "./types/DataTypes.sol";
import {ISuperformFactory} from "./interfaces/ISuperformFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {IBroadcaster} from "./interfaces/IBroadcaster.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {Error} from "./utils/Error.sol";
import {DataLib} from "./libraries/DataLib.sol";

/// @title Superforms Factory
/// @dev A secure, and easily queryable central point of access for all Superforms on any given chain,
/// @author Zeropoint Labs.
contract SuperformFactory is ISuperformFactory {
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            Constants
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_FORM_ID = 2 ** 32 - 1;
    bytes32 constant SYNC_BEACON_STATUS = keccak256("SYNC_BEACON_STATUS");

    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public immutable superRegistry;

    /// @dev all form beacon addresses
    address[] public formBeacons;

    /// @dev all superForm ids
    uint256[] public superForms;

    /// @notice If formBeaconId is 0, formBeacon is not part of the protocol
    mapping(uint32 formBeaconId => address formBeaconAddress) public formBeacon;

    mapping(address vault => uint256[] superFormIds) public vaultToSuperforms;

    mapping(address vault => uint256[] formBeaconId) public vaultToFormBeaconId;

    mapping(bytes32 vaultBeaconCombination => uint256 superFormIds) public vaultBeaconToSuperforms;

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

    /// @inheritdoc ISuperformFactory
    function addFormBeacon(
        address formImplementation_,
        uint32 formBeaconId_,
        bytes32 salt_
    ) public override onlyProtocolAdmin returns (address beacon) {
        if (formImplementation_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(formImplementation_)) revert Error.ERC165_UNSUPPORTED();
        if (formBeacon[formBeaconId_] != address(0)) revert Error.BEACON_ID_ALREADY_EXISTS();
        if (!ERC165Checker.supportsInterface(formImplementation_, type(IBaseForm).interfaceId))
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        if (formBeaconId_ > MAX_FORM_ID) revert Error.INVALID_FORM_ID();

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
    ) public override returns (uint256 superFormId_, address superForm_) {
        address tFormBeacon = formBeacon[formBeaconId_];
        if (vault_ == address(0)) revert Error.ZERO_ADDRESS();
        if (tFormBeacon == address(0)) revert Error.FORM_DOES_NOT_EXIST();
        if (formBeaconId_ > MAX_FORM_ID) revert Error.INVALID_FORM_ID();

        /// @dev Same vault and beacon can be used only once to create superform
        bytes32 vaultBeaconCombination = keccak256(abi.encode(tFormBeacon, vault_));
        if (vaultBeaconToSuperforms[vaultBeaconCombination] != 0) revert Error.VAULT_BEACON_COMBNATION_EXISTS();

        /// @dev instantiate the superForm. The initialize function call is encoded in the request
        superForm_ = address(
            new BeaconProxy(
                address(tFormBeacon),
                abi.encodeWithSelector(BaseForm(payable(address(0))).initialize.selector, superRegistry, vault_)
            )
        );

        /// @dev this will always be unique because all chainIds are unique
        superFormId_ = DataLib.packSuperform(superForm_, formBeaconId_, superRegistry.chainId());

        vaultToSuperforms[vault_].push(superFormId_);

        /// @dev Mapping vaults to formBeaconId for use in Backend
        vaultToFormBeaconId[vault_].push(formBeaconId_);

        vaultBeaconToSuperforms[vaultBeaconCombination] = superFormId_;

        superForms.push(superFormId_);

        emit SuperformCreated(formBeaconId_, vault_, superFormId_, superForm_);
    }

    /// @inheritdoc ISuperformFactory
    function createSuperforms(
        uint32[] memory formBeaconIds_,
        address[] memory vaults_
    ) external override returns (uint256[] memory superFormIds_, address[] memory superForms_) {
        superFormIds_ = new uint256[](formBeaconIds_.length);
        superForms_ = new address[](formBeaconIds_.length);

        for (uint256 i = 0; i < formBeaconIds_.length; ) {
            (superFormIds_[i], superForms_[i]) = createSuperform(formBeaconIds_[i], vaults_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ISuperformFactory
    function updateFormBeaconLogic(uint32 formBeaconId_, address newFormLogic_) external override onlyProtocolAdmin {
        if (newFormLogic_ == address(0)) revert Error.ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(newFormLogic_)) revert Error.ERC165_UNSUPPORTED();
        if (!ERC165Checker.supportsInterface(newFormLogic_, type(IBaseForm).interfaceId))
            revert Error.FORM_INTERFACE_UNSUPPORTED();
        if (formBeacon[formBeaconId_] == address(0)) revert Error.INVALID_FORM_ID();

        /// @dev form logics are not updated via broadcasting
        FormBeacon(formBeacon[formBeaconId_]).update(newFormLogic_);
    }

    /// @inheritdoc ISuperformFactory
    function changeFormBeaconPauseStatus(
        uint32 formBeaconId_,
        bool paused_,
        bytes memory extraData_
    ) external payable override onlyProtocolAdmin {
        if (formBeacon[formBeaconId_] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId_]).changePauseStatus(paused_);

        /// @dev broadcast the change in status to the other destination chains
        if (extraData_.length > 0) {
            AMBFactoryMessage memory factoryPayload = AMBFactoryMessage(
                SYNC_BEACON_STATUS,
                abi.encode(formBeaconId_, paused_)
            );

            _broadcast(abi.encode(factoryPayload), extraData_);
        }
    }

    /// @inheritdoc ISuperformFactory
    function stateSync(bytes memory data_) external payable override {
        /// @dev this function is only accessible through factory state registry
        if (msg.sender != superRegistry.factoryStateRegistry()) revert Error.NOT_FACTORY_STATE_REGISTRY();

        AMBFactoryMessage memory factoryPayload = abi.decode(data_, (AMBFactoryMessage));

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
    function isFormBeaconPaused(uint32 formBeaconId_) external view override returns (bool paused_) {
        paused_ = FormBeacon(formBeacon[formBeaconId_]).paused();
    }

    /// @inheritdoc ISuperformFactory
    function getAllSuperformsFromVault(
        address vault_
    ) external view override returns (uint256[] memory superFormIds_, address[] memory superForms_) {
        superFormIds_ = vaultToSuperforms[vault_];
        uint256 len = superFormIds_.length;
        superForms_ = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            (superForms_[i], , ) = superFormIds_[i].getSuperform();
        }
    }

    /// @inheritdoc ISuperformFactory
    function getSuperform(
        uint256 superFormId
    ) external pure override returns (address superForm_, uint32 formBeaconId_, uint64 chainId_) {
        (superForm_, formBeaconId_, chainId_) = superFormId.getSuperform();
    }

    /// @inheritdoc ISuperformFactory
    function getAllSuperforms()
        external
        view
        override
        returns (uint256[] memory superFormIds_, address[] memory superForms_)
    {
        superFormIds_ = superForms;
        uint256 len = superFormIds_.length;
        superForms_ = new address[](len);

        for (uint256 i = 0; i < len; i++) {
            (superForms_[i], , ) = superFormIds_[i].getSuperform();
        }
    }

    /// @inheritdoc ISuperformFactory
    function getFormCount() external view override returns (uint256 forms_) {
        forms_ = formBeacons.length;
    }

    /// @inheritdoc ISuperformFactory
    function getSuperformCount() external view override returns (uint256 superForms_) {
        superForms_ = superForms.length;
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
        IBroadcaster(superRegistry.factoryStateRegistry()).broadcastPayload{value: msg.value}(
            msg.sender,
            ambIds,
            message_,
            broadcastParams
        );
    }

    /// @dev synchornize beacon status update message from remote chain
    /// @notice is a part of broadcasting / dispatching through factory state registry
    /// @param message_ is the crosschain message received.
    function _syncBeaconStatus(bytes memory message_) internal {
        (uint32 formBeaconId, bool status) = abi.decode(message_, (uint32, bool));

        if (formBeacon[formBeaconId] == address(0)) revert Error.INVALID_FORM_ID();

        FormBeacon(formBeacon[formBeaconId]).changePauseStatus(status);
    }

    function getBytecodeFormBeacon(address superRegistry_, address formLogic_) public pure returns (bytes memory) {
        bytes memory bytecode = type(FormBeacon).creationCode;

        return abi.encodePacked(bytecode, abi.encode(superRegistry_, formLogic_));
    }
}
