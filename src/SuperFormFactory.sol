///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {AccessControl} from "@openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ERC165Checker} from "@openzeppelin-contracts/contracts/utils/introspection/ERC165Checker.sol";
import {BeaconProxy} from "@openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {FormBeacon} from "./forms/FormBeacon.sol";
import {BaseForm} from "./BaseForm.sol";
import "./utils/DataPacking.sol";

/// @dev FIXME - missing update call on formBeacon (factory is the admin)
/// @title SuperForms Factory
/// @dev A secure, and easily queryable central point of access for all SuperForms on any given chain,
/// @author Zeropoint Labs.
contract SuperFormFactory is ISuperFormFactory, AccessControl {
    /*///////////////////////////////////////////////////////////////
                            State Variables
    //////////////////////////////////////////////////////////////*/
    uint256 constant MAX_FORM_ID = 2 ** 80 - 1;

    /// @dev chainId represents the superform chain id.
    uint16 public immutable chainId;

    address public superRegistry;

    address[] public formBeacons;

    uint256[] public superForms;

    /// @dev formId => formAddress
    /// @notice If form[formId_] is 0, form is not part of the protocol
    mapping(uint256 => address) public form;

    /// @dev address Vault => uint256[] SuperFormIds
    mapping(address => uint256[]) public vaultToSuperForms;

    /// @dev sets caller as the admin of the contract.
    /// @param chainId_ the superform? chain id this factory is deployed on
    constructor(uint16 chainId_) {
        chainId = chainId_;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows an admin to add a form to the factory
    /// @param form_ is the address of a form
    /// @param formId_ is the id of the form
    function addForm(
        address form_,
        uint256 formId_
    ) public override onlyRole(DEFAULT_ADMIN_ROLE) returns (address beacon) {
        if (form_ == address(0)) revert ZERO_ADDRESS();
        if (!ERC165Checker.supportsERC165(form_)) revert ERC165_UNSUPPORTED();
        if (
            !ERC165Checker.supportsInterface(form_, type(IBaseForm).interfaceId)
        ) revert FORM_INTERFACE_UNSUPPORTED();

        /// @dev TODO - should we predict beacon address?
        beacon = address(new FormBeacon(form_));

        /// @dev this should instantiate the beacon for each form
        form[formId_] = beacon;

        formBeacons.push(beacon);

        emit FormAdded(form_, beacon, formId_);
    }

    /// @dev allows an admin to add a form to the factory
    /// @param forms_ are the address of a form
    /// @param formIds_ are the id of the form
    function addForms(
        address[] memory forms_,
        uint256[] memory formIds_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < forms_.length; i++) {
            addForm(forms_[i], formIds_[i]);
        }
    }

    // 5. Forms should exist based on (everything else, including deposit/withdraw/tvl etc could be done in implementations above it)
    //    1. Vault token type received (20, 4626, 721, or none)
    //   2. To get/calculate the name of the resulting Superform
    /// @dev To add new vaults to Form implementations, fusing them together into SuperForms
    /// @notice It is not possible to reliable ascertain if vault is a contract and if it is a compliant contract with a given form
    /// @notice Perhaps this can checked at form level
    /// @param formId_ is the form beacon we want to attach the vault to
    /// @param vault_ is the address of the vault
    /// @return superFormId_ is the id of the superform
    /// @dev TODO: add array version of thi
    function createSuperForm(
        uint256 formId_,
        address vault_
    ) external override returns (uint256 superFormId_, address superForm_) {
        address tForm = form[formId_];
        if (vault_ == address(0)) revert ZERO_ADDRESS();
        if (tForm == address(0)) revert FORM_DOES_NOT_EXIST();
        if (formId_ > MAX_FORM_ID) revert INVALID_FORM_ID();

        /// @dev TODO - should we predict superform address?
        /// @dev we just grab initialize selector from baseform, don't need to grab from a specific form
        superForm_ = address(
            new BeaconProxy(
                address(tForm),
                abi.encodeWithSelector(
                    BaseForm(payable(address(0))).initialize.selector,
                    chainId,
                    superRegistry,
                    vault_
                )
            )
        );

        /// @dev this will always be unique because superForm is unique.
        superFormId_ = _packSuperForm(superForm_, formId_, chainId);

        vaultToSuperForms[vault_].push(superFormId_);

        /// @dev do we need to store info of all superforms just for external querying? Could save gas here
        superForms.push(superFormId_);

        /// @dev TODO wormhole xchain spread of supervaults
        /// @notice TODO There is a problem when we want to add a new chain - how do we sync with the new contract?

        /// Next steps/proposed plan of work
        /// 1. Integration of base yield modules + Superform factory into core
        /// 2. I think StateRegistry could be upgraded to support multi message sending for all AMBs
        /// 3. Then we could create a wormhole implementation contract just like LZ with a dispatchPayload where it performs the above actions
        /// 4. SuperFormFactory could be given CORE_CONTRACTS_ROLE to achieve the above

        emit SuperFormCreated(formId_, vault_, superFormId_, superForm_);
    }

    /// @inheritdoc ISuperFormFactory
    function updateFormBeaconLogic(
        uint256 formId_,
        address newFormLogic_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        FormBeacon(form[formId_]).update(newFormLogic_);
    }

    /// set super registry
    /// @dev allows an admin to set the super registry
    /// @param superRegistry_ is the address of the super registry
    function setSuperRegistry(
        address superRegistry_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (superRegistry_ == address(0)) revert ZERO_ADDRESS();
        superRegistry = superRegistry_;
        emit SuperRegistrySet(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                         External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the address of a form
    /// @param formId_ is the id of the form
    /// @return form_ is the address of the form
    function getForm(
        uint256 formId_
    ) external view override returns (address form_) {
        form_ = form[formId_];
    }

    /// @dev Reverse query of getSuperForm, returns all superforms for a given vault
    /// @param vault_ is the address of a vault
    /// @return superFormIds_ is the id of the superform
    /// @return formIds_ is the form id
    /// @return chainIds_ is the chain id
    function getAllSuperFormsFromVault(
        address vault_
    )
        external
        view
        override
        returns (
            uint256[] memory superFormIds_,
            uint256[] memory formIds_,
            uint16[] memory chainIds_
        )
    {
        superFormIds_ = vaultToSuperForms[vault_];
        uint256 len = superFormIds_.length;
        formIds_ = new uint256[](len);
        chainIds_ = new uint16[](len);

        for (uint256 i = 0; i < len; i++) {
            (, formIds_[i], chainIds_[i]) = _getSuperForm(superFormIds_[i]);
        }
    }

    /// @dev Returns all SuperForms
    /// @return superFormIds_ is the id of the superform
    /// @return superForms_ is the address of the vault
    /// @return formIds_ is the form id
    /// @return chainIds_ is the chain id
    function getAllSuperForms()
        external
        view
        override
        returns (
            uint256[] memory superFormIds_,
            address[] memory superForms_,
            uint256[] memory formIds_,
            uint16[] memory chainIds_
        )
    {
        superFormIds_ = superForms;
        uint256 len = superFormIds_.length;
        superForms_ = new address[](len);
        formIds_ = new uint256[](len);
        chainIds_ = new uint16[](len);

        for (uint256 i = 0; i < len; i++) {
            (superForms_[i], formIds_[i], chainIds_[i]) = _getSuperForm(
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
