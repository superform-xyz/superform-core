///SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IERC4626Form } from "./IERC4626Form.sol";
import { InitSingleVaultData, TimelockPayload } from "../../types/DataTypes.sol";

/// @title IERC4626TimelockForm
/// @author Zeropoint Labs
/// @notice Interface used by ERC4626TimelockForm. Required by TimelockStateRegistry to call processUnlock()
/// function
interface IERC4626TimelockForm is IERC4626Form {
    /// @notice Process unlock request
    function withdrawAfterCoolDown(uint256 amount_, TimelockPayload memory p_) external;

    function unlockId(uint256 unlockCounter_) external view returns (InitSingleVaultData memory singleVaultData);
}
