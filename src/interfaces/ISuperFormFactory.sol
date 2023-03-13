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
    /// @param formId is the id of the new form
    event FormCreated(address indexed form, uint256 indexed formId);

    /// @dev emitted when a new SuperForm is created
    /// @param formId is the id of the form
    /// @param vault is the address of the vault
    /// @param superFormId is the id of the superform - pair (form,vault)
    event SuperFormCreated(
        uint256 indexed formId,
        address indexed vault,
        uint256 indexed superFormId
    );

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows an admin to enter a form to the factory
    /// @param form_ is the address of a form
    /// @return formId_ is the id of the form
    function addForm(address form_) external returns (uint256 formId_);

    /// @dev To add new vaults to Form implementations, fusing them together into SuperForms
    /// @param formId_ is the formId we want to attach the vault to
    /// @param vault_ is the address of a vault
    /// @return superFormId_ is the id of the superform
    function createSuperForm(
        uint256 formId_,
        address vault_
    ) external returns (uint256 superFormId_);

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the address of a form
    /// @param formId_ is the id of the form
    /// @return form_ is the address of the form
    function getForm(uint256 formId_) external view returns (address form_);

    /// @dev returns the form-vault pair of a superform
    /// @param superFormId_ is the id of the superform
    /// @return vault_ is the address of the vault
    /// @return formId_ is the form id
    /// @return chainId_ is the chain id
    function getSuperForm(
        uint256 superFormId_
    ) external view returns (address vault_, uint256 formId_, uint256 chainId_);

    /// @dev returns the vault-form-chain pair of an array of superforms
    /// @param superFormIds_  array of superforms
    /// @return vaults_ are the address of the vaults
    /// @return formIds_ are the form ids
    /// @return chainIds_ are the chain ids
    function getSuperForms(
        uint256[] memory superFormIds_
    )
        external
        view
        returns (
            address[] memory vaults_,
            uint256[] memory formIds_,
            uint256[] memory chainIds_
        );

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
            uint256[] memory chainIds_
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
            uint256[] memory chainIds_
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
