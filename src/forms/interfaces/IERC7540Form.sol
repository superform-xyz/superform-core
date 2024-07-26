// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC4626Form } from "./IERC4626Form.sol";
import { InitSingleVaultData, TimelockPayload, LiqRequest } from "../../types/DataTypes.sol";
import { SyncWithdrawTxDataPayload } from "../../interfaces/IAsyncStateRegistry.sol";

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
    function claimDeposit(
        address user_,
        uint256 superformId_,
        uint256 amountToClaim_,
        bool retain4626_
    )
        external
        returns (uint256 shares);

    /// @dev this function is called the withdraw request is ready to be claimed
    function claimWithdraw(
        address user_,
        uint256 superformId_,
        uint256 amountToClaim_,
        uint256 maxSlippage_,
        uint8 isXChain_,
        uint64 srcChainId_,
        LiqRequest memory liqData_
    )
        external
        returns (uint256 assets);

    /// @dev this function is called when txData has been updated for asyncDeposit forms wheneve required
    /// @param p_ the payload data
    /// @return assets the amount of assets redeemed
    function syncWithdrawTxData(SyncWithdrawTxDataPayload memory p_) external returns (uint256 assets);
}

/// @title IERC7540Form
/// @dev Interface used by ERC7540Form. Required by AsyncStateRegistry
/// @author Zeropoint Labs
interface IERC7540Form is IERC7540FormBase, IERC4626Form { }
