// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiqRequest, AMBMessage} from "../types/DataTypes.sol";

/// @title ICoreStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Core State Registry
interface ICoreStateRegistry {
    /*///////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/
    /// @dev local struct to avoid stack too deep errors in `processPayload`
    struct CoreProcessPayloadLocalVars {
        bytes _payloadBody;
        uint256 _payloadHeader;
        uint8 txType;
        uint8 callbackType;
        uint8 multi;
        address srcSender;
        uint64 srcChainId;
        AMBMessage _message;
        bytes returnMessage;
        bytes32 _proof;
    }

    /// @dev local struct to avoid stack too deep errors in `updateWithdrawPayload`
    struct UpdateWithdrawPayloadVars {
        bytes32 prevPayloadProof;
        bytes prevPayloadBody;
        uint256 prevPayloadHeader;
        uint8 isMulti;
        uint64 srcChainId;
        uint64 dstChainId;
        address srcSender;
    }

    /// @dev local struct to avoid stack too deep errors in `updateDepositPayload`
    struct UpdateDepositPayloadVars {
        bytes32 prevPayloadProof;
        bytes prevPayloadBody;
        uint256 prevPayloadHeader;
        uint64 srcChainId;
        uint8 isMulti;
    }

    /*///////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev is emitted when any deposit fails
    event FailedXChainDeposits(uint256 indexed payloadId);

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev allows accounts with {CORE_STATE_REGISTRY_UPDATER_ROLE} to modify a received cross-chain deposit payload.
    /// @param payloadId_ is the identifier of the cross-chain payload to be updated.
    /// @param finalAmounts_ is the amount to be updated.
    /// NOTE: amounts cannot be updated beyond user specified safe slippage limit.
    function updateDepositPayload(uint256 payloadId_, uint256[] calldata finalAmounts_) external;

    /// @dev allows accounts with {CORE_STATE_REGISTRY_UPDATER_ROLE} to modify a received cross-chain withdraw payload.
    /// @param payloadId_  is the identifier of the cross-chain payload to be updated.
    /// @param txData_ is the transaction data to be updated.
    function updateWithdrawPayload(uint256 payloadId_, bytes[] calldata txData_) external;

    /// @dev allows accounts with {CORE_STATE_REGISTRY_PROCESSOR_ROLE} to rescue tokens on failed deposits
    /// @param payloadId_ is the identifier of the cross-chain payload.
    /// @param liqDatas_ is the array of liquidity data.
    function rescueFailedDeposits(uint256 payloadId_, LiqRequest[] memory liqDatas_) external payable;
}
