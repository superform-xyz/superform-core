// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title ISuperFormFactory
/// @author ZeroPoint Labs
/// @notice Interface for SuperForm Factory
interface ISuperFormFactory {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    /// @dev emitted when a new form beacon is entered into the factory
    /// @param formImplementation is the address of the new form implementation
    /// @param beacon is the address of the beacon
    /// @param formBeaconId is the id of the new form beacon
    event FormBeaconAdded(address indexed formImplementation, address indexed beacon, uint256 indexed formBeaconId);

    /// @dev emitted when a new SuperForm is created
    /// @param formBeaconId is the id of the form beacon
    /// @param vault is the address of the vault
    /// @param superFormId is the id of the superform - pair (form,vault)
    /// @param superForm is the address of the superform
    event SuperFormCreated(
        uint256 indexed formBeaconId,
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

    /// @dev allows an admin to add a FormBeacon to the factory
    /// @param formImplementation_ is the address of a form implementation
    /// @param formBeaconId_ is the to-be id of the form beacon
    /// @param salt_ is the salt for create2
    function addFormBeacon(
        address formImplementation_,
        uint256 formBeaconId_,
        bytes32 salt_
    ) external returns (address beacon);

    /// @dev allows an admin to add Form Beacons to the factory
    /// @param formImplementations_ are the address of form implementaions
    /// @param formBeaconIds_ are the to-be ids of the form beacons
    /// @param salt_ is the salt for create2
    function addFormBeacons(
        address[] memory formImplementations_,
        uint256[] memory formBeaconIds_,
        bytes32 salt_
    ) external;

    // 5. Forms should exist based on (everything else, including deposit/withdraw/tvl etc could be done in implementations above it)
    //    1. Vault token type received (20, 4626, 721, or none)
    //   2. To get/calculate the name of the resulting Superform
    /// @dev To add new vaults to Form implementations, fusing them together into SuperForms
    /// @notice It is not possible to reliable ascertain if vault is a contract and if it is a compliant contract with a given form
    /// @notice Perhaps this can checked at form level
    /// @param formBeaconId_ is the form beacon we want to attach the vault to
    /// @param vault_ is the address of the vault
    /// @param broadcastParams_ is the AMBExtraData to be sent to the AMBs
    /// @return superFormId_ is the id of the superform
    /// @dev TODO: add array version of this
    function createSuperForm(
        uint256 formBeaconId_,
        address vault_,
        bytes calldata broadcastParams_
    ) external payable returns (uint256 superFormId_, address superForm_);

    /// @dev to synchronize superforms added to different chains using factory registry
    /// @param data_ is the cross-chain superform id
    function stateSync(bytes memory data_) external payable;

    /// @dev allows an admin to update the logic of a form
    /// @param formBeaconId_ is the id of the form beacon
    /// @param newFormLogic_ is the address of the new form logic
    function updateFormBeaconLogic(uint256 formBeaconId_, address newFormLogic_) external;

    /// @dev allows an admin to change the status of a form
    /// @param formBeaconId_ is the id of the form beacon
    /// @param status_ is the new status
    /// @param extraData_ is optional & passed when broadcasting of status is needed
    function changeFormBeaconPauseStatus(uint256 formBeaconId_, bool status_, bytes memory extraData_) external payable;

    /*///////////////////////////////////////////////////////////////
                            View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the address of a form beacon
    /// @param formBeaconId_ is the id of the beacon form
    /// @return formBeacon_ is the address of the beacon form
    function getFormBeacon(uint256 formBeaconId_) external view returns (address formBeacon_);

    /// @dev returns the status of form beacon
    /// @param formBeaconId_ is the id of the beacon form
    /// @return status_ is the current status of the form beacon
    function getFormBeaconStatus(uint256 formBeaconId_) external view returns (bool status_);

    /// @dev returns the address of a superform
    /// @param superFormId_ is the id of the superform
    /// @return superForm_ is the address of the superform
    /// @return formBeaconId_ is the id of the form beacon
    /// @return chainId_ is the chain id
    function getSuperForm(
        uint256 superFormId_
    ) external pure returns (address superForm_, uint256 formBeaconId_, uint16 chainId_);

    /// @dev Reverse query of getSuperForm, returns all superforms for a given vault
    /// @param vault_ is the address of a vault
    /// @return superFormIds_ is the id of the superform
    /// @return superForms_ is the address of the superform
    /// @return formBeaconIds_ is the form id
    /// @return chainIds_ is the chain id
    function getAllSuperFormsFromVault(
        address vault_
    )
        external
        view
        returns (
            uint256[] memory superFormIds_,
            address[] memory superForms_,
            uint256[] memory formBeaconIds_,
            uint16[] memory chainIds_
        );

    /// @dev Returns all SuperForms
    /// @return superFormIds_ is the id of the superform
    /// @return vaults_ is the address of the vault
    /// @return formBeaconIds_ is the form id
    /// @return chainIds_ is the chain id
    function getAllSuperForms()
        external
        view
        returns (
            uint256[] memory superFormIds_,
            address[] memory vaults_,
            uint256[] memory formBeaconIds_,
            uint16[] memory chainIds_
        );

    /// @dev returns the number of forms
    /// @return forms_ is the number of forms
    function getAllFormsList() external view returns (uint256 forms_);

    /// @dev returns the number of superforms
    /// @return superForms_ is the number of superforms
    function getAllSuperFormsList() external view returns (uint256 superForms_);

    /// @dev returns the number of superforms for the given chain (where this call is made)
    function getAllChainSuperFormsList() external view returns (uint256 superForms_);
}
