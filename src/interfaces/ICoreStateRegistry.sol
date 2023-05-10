// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
import {LiqRequest} from "../types/DataTypes.sol";

interface ICoreStateRegistry {
    /// @dev emited if any deposit fails
    event FailedXChainDeposits(uint256 indexed payloadId);

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updateMultiVaultPayload(
        uint256 payloadId_,
        uint256[] calldata finalAmounts_
    ) external;

    /// @dev allows accounts with {UPDATER_ROLE} to modify a received cross-chain payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmount_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updateSingleVaultPayload(
        uint256 payloadId_,
        uint256 finalAmount_
    ) external;

    /// @dev allows accounts with {PROCESSOR_ROLE} to rescue tokens on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param liqDatas_ is the array of liquidity data.
    function rescueFailedMultiDeposits(
        uint256 payloadId_,
        LiqRequest[] memory liqDatas_
    ) external payable;

    /// @dev allows accounts with {PROCESSOR_ROLE} to rescue tokens on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param liqData_ is the liquidity data.
    function rescueFailedDeposit(
        uint256 payloadId_,
        LiqRequest memory liqData_
    ) external payable;
}
