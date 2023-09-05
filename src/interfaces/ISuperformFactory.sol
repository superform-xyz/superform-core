// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ISuperformFactory
/// @author ZeroPoint Labs
/// @notice Interface for Superform Factory
interface ISuperformFactory {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a new form beacon is entered into the factory
    /// @param formImplementation is the address of the new form implementation
    /// @param beacon is the address of the beacon
    /// @param formBeaconId is the id of the new form beacon
    event FormBeaconAdded(address indexed formImplementation, address indexed beacon, uint256 indexed formBeaconId);

    /// @dev emitted when a new Superform is created
    /// @param formBeaconId is the id of the form beacon
    /// @param vault is the address of the vault
    /// @param superformId is the id of the superform
    /// @param superform is the address of the superform
    event SuperformCreated(
        uint256 indexed formBeaconId, address indexed vault, uint256 indexed superformId, address superform
    );

    /// @dev emitted when a new SuperRegistry is set
    /// @param superRegistry is the address of the super registry
    event SuperRegistrySet(address indexed superRegistry);

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows an admin to add a FormBeacon to the factory
    /// @param formImplementation_ is the address of a form implementation
    /// @param formBeaconId_ is the id of the form beacon (generated off-chain and equal in all chains)
    /// @param salt_ is the salt for create2
    function addFormBeacon(
        address formImplementation_,
        uint32 formBeaconId_,
        bytes32 salt_
    )
        external
        returns (address beacon);

    /// @dev To add new vaults to Form implementations, fusing them together into Superforms
    /// @param formBeaconId_ is the form beacon we want to attach the vault to
    /// @param vault_ is the address of the vault
    /// @return superformId_ is the id of the created superform
    /// @return superform_ is the address of the created superform
    function createSuperform(
        uint32 formBeaconId_,
        address vault_
    )
        external
        returns (uint256 superformId_, address superform_);

    /// @dev To add new vaults to Form implementations, fusing them together into Superforms
    /// @param formBeaconIds_ are the form beacon ids we want to attach the vaults to
    /// @param vaults_ are the addresses of the vaults
    /// @return superformIds_ are the id of the created superforms
    /// @return superforms_ are the addresses of the created superforms
    function createSuperforms(
        uint32[] memory formBeaconIds_,
        address[] memory vaults_
    )
        external
        returns (uint256[] memory superformIds_, address[] memory superforms_);

    /// @dev to synchronize superforms added to different chains using broadcast registry
    /// @param data_ is the cross-chain superform id
    function stateSyncBroadcast(bytes memory data_) external payable;

    /// @dev allows an admin to update the logic of a form
    /// @param formBeaconId_ is the id of the form beacon
    /// @param newFormLogic_ is the address of the new form logic
    function updateFormBeaconLogic(uint32 formBeaconId_, address newFormLogic_) external;

    /// @dev allows an admin to change the status of a form
    /// @param formBeaconId_ is the id of the form beacon
    /// @param status_ is the new status
    /// @param extraData_ is optional & passed when broadcasting of status is needed
    function changeFormBeaconPauseStatus(
        uint32 formBeaconId_,
        uint256 status_,
        bytes memory extraData_
    )
        external
        payable;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the address of a form beacon
    /// @param formBeaconId_ is the id of the beacon form
    /// @return formBeacon_ is the address of the beacon form
    function getFormBeacon(uint32 formBeaconId_) external view returns (address formBeacon_);

    /// @dev returns the paused status of form beacon
    /// @param formBeaconId_ is the id of the beacon form
    /// @return paused_ is the current paused status of the form beacon
    function isFormBeaconPaused(uint32 formBeaconId_) external view returns (uint256 paused_);

    /// @dev returns the address of a superform
    /// @param superformId_ is the id of the superform
    /// @return superform_ is the address of the superform
    /// @return formBeaconId_ is the id of the form beacon
    /// @return chainId_ is the chain id
    function getSuperform(uint256 superformId_)
        external
        pure
        returns (address superform_, uint32 formBeaconId_, uint64 chainId_);

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

    /// @dev returns the number of forms
    /// @return forms_ is the number of forms
    function getFormCount() external view returns (uint256 forms_);

    /// @dev returns the number of superforms
    /// @return superforms_ is the number of superforms
    function getSuperformCount() external view returns (uint256 superforms_);
}
