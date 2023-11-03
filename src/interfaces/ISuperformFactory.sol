// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

/// @title ISuperformFactory
/// @author ZeroPoint Labs
/// @notice Interface for Superform Factory
interface ISuperformFactory {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a new formImplementation is entered into the factory
    /// @param formImplementation is the address of the new form implementation
    /// @param formImplementationId is the id of the formImplementation
    event FormImplementationAdded(address indexed formImplementation, uint256 indexed formImplementationId);

    /// @dev emitted when a new Superform is created
    /// @param formImplementationId is the id of the form implementation
    /// @param vault is the address of the vault
    /// @param superformId is the id of the superform
    /// @param superform is the address of the superform
    event SuperformCreated(
        uint256 indexed formImplementationId, address indexed vault, uint256 indexed superformId, address superform
    );

    /// @dev emitted when a new SuperRegistry is set
    /// @param superRegistry is the address of the super registry
    event SuperRegistrySet(address indexed superRegistry);

    /// @dev emitted when a form implementation is paused
    /// @param formImplementationId is the id of the form implementation
    /// @param paused is the new paused status
    event FormImplementationPaused(uint256 indexed formImplementationId, bool indexed paused);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows an admin to add a Form implementation to the factory
    /// @param formImplementation_ is the address of a form implementation
    /// @param formImplementationId_ is the id of the form implementation (generated off-chain and equal in all chains)
    function addFormImplementation(address formImplementation_, uint32 formImplementationId_) external;

    /// @dev To add new vaults to Form implementations, fusing them together into Superforms
    /// @param formImplementationId_ is the form implementation we want to attach the vault to
    /// @param vault_ is the address of the vault
    /// @return superformId_ is the id of the created superform
    /// @return superform_ is the address of the created superform
    function createSuperform(
        uint32 formImplementationId_,
        address vault_
    )
        external
        returns (uint256 superformId_, address superform_);

    /// @dev to synchronize superforms added to different chains using broadcast registry
    /// @param data_ is the cross-chain superform id
    function stateSyncBroadcast(bytes memory data_) external payable;

    /// @dev allows an admin to change the status of a form
    /// @param formImplementationId_ is the id of the form implementation
    /// @param status_ is the new status
    /// @param extraData_ is optional & passed when broadcasting of status is needed
    function changeFormImplementationPauseStatus(
        uint32 formImplementationId_,
        bool status_,
        bytes memory extraData_
    )
        external
        payable;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the number of forms
    /// @return forms_ is the number of forms
    function getFormCount() external view returns (uint256 forms_);

    /// @dev returns the number of superforms
    /// @return superforms_ is the number of superforms
    function getSuperformCount() external view returns (uint256 superforms_);

    /// @dev returns the address of a form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return formImplementation_ is the address of the form implementation
    function getFormImplementation(uint32 formImplementationId_) external view returns (address formImplementation_);

    /// @dev returns the paused status of form implementation
    /// @param formImplementationId_ is the id of the form implementation
    /// @return paused_ is the current paused status of the form formImplementationId_
    function isFormImplementationPaused(uint32 formImplementationId_) external view returns (bool paused_);

    /// @dev returns the address of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formImplementationId_ is the id of the form implementation
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        external
        pure
        returns (address superform_, uint32 formImplementationId_, uint64 chainId_);

    /// @dev returns if an address has been added to a Form
    /// @param superformId_ is the id of the superform
    /// @return isSuperform_ bool if it exists
    function isSuperform(uint256 superformId_) external view returns (bool isSuperform_);

    /// @dev Reverse query of getSuperform, returns all superforms for a given vault
    /// @param vault_ is the address of a vault
    /// @return superformIds_ is the id of the superform
    /// @return superforms_ is the address of the superform
    function getAllSuperformsFromVault(address vault_)
        external
        view
        returns (uint256[] memory superformIds_, address[] memory superforms_);

    /// @dev Returns all Superforms
    /// @return superformIds_ is the id of the superform
    /// @return vaults_ is the address of the vault
    function getAllSuperforms() external view returns (uint256[] memory superformIds_, address[] memory vaults_);
}
