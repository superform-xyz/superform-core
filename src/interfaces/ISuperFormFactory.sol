// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface ISuperFormFactory {
    /*///////////////////////////////////////////////////////////////
                                Errors
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a vault address is 0
    error ZERO_ADDRESS();

    /// @dev emitted when a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev emitted when a form is not FORM interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev emitted when a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev emitted when a SuperForm already exists
    error SUPERFORM_ALREADY_EXISTS();

    /// @dev emitted when a SuperForm does not exist
    error SUPERFORM_DOES_NOT_EXIST();

    /// @dev emitted when form id is larger than max uint16
    error INVALID_FORM_ID();

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a new form is entered into the factory
    /// @param form is the address of the new form
    /// @param beacon is the address of the beacon
    /// @param formId is the id of the new form
    event FormAdded(
        address indexed form,
        address indexed beacon,
        uint256 indexed formId
    );

    /// @dev emitted when a new SuperForm is created
    /// @param formId is the id of the form
    /// @param vault is the address of the vault
    /// @param superFormId is the id of the superform - pair (form,vault)
    event SuperFormCreated(
        uint256 indexed formId,
        address indexed vault,
        uint256 indexed superFormId,
        address superForm
    );

    /// @dev emitted when a new SuperRegistry is set
    /// @param superRegistry is the address of the super registry
    event SuperRegistrySet(address indexed superRegistry);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows an admin to enter a form to the factory
    /// @param form_ is the address of a form
    /// @param formId_ is the id of the form
    function addForm(
        address form_,
        uint256 formId_
    ) external returns (address beacon_);

    /// @dev allows an admin to add a form to the factory
    /// @param forms_ are the address of a form
    /// @param formIds_ are the id of the form
    function addForms(
        address[] memory forms_,
        uint256[] memory formIds_
    ) external;

    /// @dev To add new vaults to Form implementations, fusing them together into SuperForms
    /// @param formId_ is the formId we want to attach the vault to
    /// @param vault_ is the address of a vault
    /// @return superFormId_ is the id of the superform
    function createSuperForm(
        uint256 formId_,
        address vault_
    ) external returns (uint256 superFormId_, address superForm_);

    /// @dev allows an admin to update the beacon logic of a form
    /// @param formId_ is the id of the form
    /// @param newFormLogic_ is the address of the new form logic
    function updateFormBeaconLogic(
        uint256 formId_,
        address newFormLogic_
    ) external;

    /// set super registry
    /// @dev allows an admin to set the super registry
    /// @param superRegistry_ is the address of the super registry
    function setSuperRegistry(address superRegistry_) external;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the address of a form
    /// @param formId_ is the id of the form
    /// @return form_ is the address of the form
    function getForm(uint256 formId_) external view returns (address form_);

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
        returns (
            uint256[] memory superFormIds_,
            uint256[] memory formIds_,
            uint16[] memory chainIds_
        );

    /// @dev Returns all SuperForms
    /// @return superFormIds_ is the id of the superform
    /// @return vaults_ is the address of the vault
    /// @return formIds_ is the form id
    /// @return chainIds_ is the chain id
    function getAllSuperForms()
        external
        view
        returns (
            uint256[] memory superFormIds_,
            address[] memory vaults_,
            uint256[] memory formIds_,
            uint16[] memory chainIds_
        );

    /// @dev returns the number of forms
    /// @return forms_ is the number of forms
    function getAllFormsList() external view returns (uint256 forms_);

    /// @dev returns the number of superforms
    /// @return superForms_ is the number of superforms
    function getAllSuperFormsList() external view returns (uint256 superForms_);

    /// @dev returns the number of superforms for the given chain (where this call is made)
    function getAllChainSuperFormsList()
        external
        view
        returns (uint256 superForms_);
}
