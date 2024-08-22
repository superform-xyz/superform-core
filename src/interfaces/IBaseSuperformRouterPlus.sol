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
    /// @param csrSrcPayloadId The ID of the csr payload generated on source for sending the message
    event DisbursementCompleted(address indexed receiver, uint256 indexed csrSrcPayloadId);

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
    /// @param csrSrcPayloadId_ The ID of the csr payload generated on source for sending the message
    function finalizeDisbursement(uint256 csrSrcPayloadId_) external;

    /// @notice completes multiple disbursements in a batch
    /// @param csrSrcPayloadIds_ The ID of the csr payloads generated on source for sending the message
    function finalizeBatchDisbursement(uint256[] calldata csrSrcPayloadIds_) external;
}
