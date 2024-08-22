// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IBaseSuperformRouterPlus {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown when a non-processor attempts to call a processor-only function
    error NOT_ROUTER_PLUS_PROCESSOR();
    //////////////////////////////////////////////////////////////
    //                       STRUCTS                             //
    //////////////////////////////////////////////////////////////

    struct XChainRebalanceData {
        bytes4 rebalanceSelector;
        bool smartWallet;
        address interimAsset;
        uint256 slippage;
        uint256 expectedAmountInterimAsset;
        bytes rebalanceToAmbIds;
        bytes rebalanceToDstChainIds;
        bytes rebalanceToSfData;
    }

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    /// @notice emitted when a disbursement is completed
    /// @param receiver The address receiving the disbursed tokens
    /// @param payloadId The ID of the disbursement payload
    event DisbursementCompleted(address indexed receiver, uint256 indexed payloadId);

    //////////////////////////////////////////////////////////////
    //                       ENUMS                             //
    //////////////////////////////////////////////////////////////

    enum Actions {
        DEPOSIT,
        REBALANCE_FROM_SINGLE,
        REBALANCE_FROM_MULTI,
        REBALANCE_X_CHAIN_FROM_SINGLE,
        REBALANCE_X_CHAIN_FROM_MULTI
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @notice completes the disbursement process
    /// @param csrAckPayloadId_ The payload ID to complete the disbursement
    function finalizeDisbursement(uint256 csrAckPayloadId_) external;

    /// @notice completes multiple disbursements in a batch
    /// @param csrAckPayloadIds_ The payload IDs to complete the disbursements
    function finalizeBatchDisbursement(uint256[] calldata csrAckPayloadIds_) external;
}
