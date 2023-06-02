///SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {InitSingleVaultData} from "../../types/DataTypes.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

/// @notice Interface for ERC4626 extended with Timelock design (ERC4626MockVault)
/// NOTE: Not a Form interface!
interface IERC4626TimelockVault is IERC4626 {
    /*///////////////////////////////////////////////////////////////
                            TIMELOCK SECTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Data structure for unlock request. In production vaults have differing mechanism for this
    struct UnlockRequest {
        /// Unique id of the request
        uint id;
        // The timestamp at which the `shareAmount` was requested to be unlocked
        uint startedAt;
        // The amount of shares to burn
        uint shareAmount;
    }

    /// @notice Abstract function, demonstrating a need for two separate calls to withdraw from IERC4626TimelockVault target vault
    /// @dev Owner first submits request for unlock and only after specified cooldown passes, can withdraw
    function requestUnlock(uint shareAmount, address owner) external;

    /// @notice Abstract function, demonstrating a need for two separate calls to withdraw from IERC4626TimelockVault target vault
    /// @dev Owner can resign from unlock request. In production vaults have differing mechanism for this
    function cancelUnlock(address owner) external;

    /// @notice Check outstanding unlock request for the owner
    /// @dev Mock Timelocked Vault uses single UnlockRequest. In production vaults have differing mechanism for this
    function userUnlockRequests(address owner) external view returns (UnlockRequest memory);

    /// @notice The amount of time that must pass between a requestUnlock() and withdraw() call.
    function getLockPeriod() external view returns (uint256);
}
