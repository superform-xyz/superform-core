///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC4626Form} from "../../test/interfaces/IERC4626Form.sol";
import {InitSingleVaultData} from "../../types/DataTypes.sol";

/// @title IERC4626TimelockForm
/// @notice Interface used by ERC4626TimelockForm. Required by TwostepsFormStateRegistry to call processUnlock() function
interface IERC4626TimelockForm is IERC4626Form {
 
    /// @notice Process unlock request
    /// @param owner is the srcSender of the payload during 1st step
    function processUnlock(address owner) external;

    /// @notice Getter for returning singleVaultData from the Form to the FormKeeper
    function unlockId(address owner) external view returns (InitSingleVaultData memory singleVaultData);
}