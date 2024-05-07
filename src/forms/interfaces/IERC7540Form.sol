// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC4626Form } from "./IERC4626Form.sol";
import { InitSingleVaultData, TimelockPayload } from "../../types/DataTypes.sol";
import { AsyncWithdrawPayload, AsyncDepositPayload } from "../../interfaces/IAsyncStateRegistry.sol";

/// @title IERC7540FormBase
/// @author Zeropoint Labs
interface IERC7540FormBase {
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    function getPendingDepositRequest(uint256 requestId, address owner) external view returns (uint256 pendingAssets);

    function getClaimableDepositRequest(
        uint256 requestId,
        address owner
    )
        external
        view
        returns (uint256 claimableAssets);

    function getPendingRedeemRequest(uint256 requestId, address owner) external view returns (uint256 pendingShares);

    function getClaimableRedeemRequest(
        uint256 requestId,
        address owner
    )
        external
        view
        returns (uint256 claimableShares);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev this function is called when the shares are ready to be transferred to the form or to receiverAddress (if
    /// retain4626 is set)
    /// @param p_ the payload data
    /// @return shares the amount of shares minted
    function claimDeposit(AsyncDepositPayload memory p_) external returns (uint256 shares);

    /// @dev this function is called the withdraw request is ready to be claimed
    /// @dev retain4626 flag is not added in this implementation unlike in ERC4626Implementation.sol because
    /// @dev if a vault fails to redeem at this stage, superPositions are minted back to the user and he can
    /// @dev try again with retain4626 flag set and take their shares directly
    /// @param p_ the payload data
    /// @return assets the amount of assets withdrawn
    function claimWithdraw(AsyncWithdrawPayload memory p_) external returns (uint256 assets);
}

/// @title IERC7540Form
/// @dev Interface used by ERC7540Form. Required by AsyncStateRegistry
/// @author Zeropoint Labs
interface IERC7540Form is IERC7540FormBase, IERC4626Form { }
