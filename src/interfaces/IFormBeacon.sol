// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IFormBeacon
/// @author ZeroPoint Labs
/// @dev interface for arbitrary message bridge implementation
interface IFormBeacon {
    /*///////////////////////////////////////////////////////////////
                    Events
    //////////////////////////////////////////////////////////////*/
    /// @dev emited when form beacon logic is updated
    event FormLogicUpdated(address indexed oldLogic, address indexed newLogic);

    /// @dev emited when form beacon status is changed
    event FormBeaconPaused(bool paused);

    /*///////////////////////////////////////////////////////////////
                        External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev updates form logic
    /// @param formLogic_ is the new form logic contract
    function update(address formLogic_) external;

    /// @dev changes the paused status of the form
    /// @param newStatus_ is the new status
    function changePauseStatus(bool newStatus_) external;

    /*///////////////////////////////////////////////////////////////
                        External View Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the current form logic contract
    function implementation() external view returns (address);

    /// @dev returns true if the form is paused
    function paused() external view returns (bool);
}
