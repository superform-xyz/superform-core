// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { LiqRequest } from "src/types/DataTypes.sol";
import { IBaseSuperformRouterPlus } from "./IBaseSuperformRouterPlus.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface ISuperformRouterPlusAsync is IBaseSuperformRouterPlus {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown when a non-processor attempts to call a processor-only function
    error NOT_ROUTER_PLUS_PROCESSOR();

    /// @notice thrown if the caller is not router plus
    error NOT_ROUTER_PLUS();

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_INVALID_TX_DATA_UPDATE();

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_DIFFERENT_TOKEN();

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_DIFFERENT_BRIDGE_ID();

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_DIFFERENT_CHAIN();

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_DIFFERENT_RECEIVER();

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_AMOUNT_OUT_OF_SLIPPAGE(uint256 newAmount, uint256 expectedAmount, uint256 userSlippage);

    /// @notice thrown if the rebalance to update is invalid
    error COMPLETE_REBALANCE_OUTPUTAMOUNT_OUT_OF_SLIPPAGE(
        uint256 newOutputAmount, uint256 expectedOutputAmount, uint256 userSlippage
    );

    /// @notice thrown to avoid processing the same rebalance payload twice
    error REBALANCE_ALREADY_PROCESSED();

    /// @notice thrown when the refund proposer is invalid
    error INVALID_PROPOSER();

    /// @notice thrown when the refund payload is invalid
    error INVALID_REFUND_DATA();

    /// @notice thrown when refund is already proposed
    error REFUND_ALREADY_PROPOSED();

    /// @notice thrown if the refund is still in dispute phase
    error IN_DISPUTE_PHASE();

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    /// @notice emitted when a cross-chain rebalance is completed
    /// @param receiver The address receiving the rebalanced position
    /// @param routerPlusPayloadId The router plus payload id of the rebalance
    event XChainRebalanceComplete(address indexed receiver, uint256 indexed routerPlusPayloadId);

    /// @notice emitted when a new refund is created
    /// @param routerPlusPayloadId is the unique identifier for the payload
    /// @param refundReceiver is the address of the user who'll receiver the refund
    /// @param refundToken is the token to be refunded
    /// @param refundAmount is the new refund amount
    event RefundInitiated(
        uint256 indexed routerPlusPayloadId, address indexed refundReceiver, address refundToken, uint256 refundAmount
    );

    /// @notice emitted when an existing refund got disputed
    /// @param routerPlusPayloadId is the unique identifier for the payload
    /// @param disputer is the address of the user who disputed the refund
    event RefundDisputed(uint256 indexed routerPlusPayloadId, address indexed disputer);

    /// @notice emitted when a new refund amount is proposed
    /// @param routerPlusPayloadId is the unique identifier for the payload
    /// @param newRefundAmount is the new refund amount proposed
    event NewRefundAmountProposed(uint256 indexed routerPlusPayloadId, uint256 indexed newRefundAmount);

    /// @notice emitted when a refund is complete
    /// @param routerPlusPayloadId is the unique identifier for the payload
    /// @param caller is the address of the user who called the function
    event RefundCompleted(uint256 indexed routerPlusPayloadId, address indexed caller);

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

    struct Refund {
        address receiver;
        address interimToken;
        uint256 amount;
        uint256 proposedTime;
    }

    struct DecodedRouterPlusRebalanceCallData {
        address interimAsset;
        bytes4 rebalanceSelector;
        uint256 userSlippage;
        address[] receiverAddress;
        uint256[][] superformIds;
        uint256[][] amounts;
        uint256[][] outputAmounts;
        uint8[][] ambIds;
        uint64[] dstChainIds;
    }

    struct CompleteCrossChainRebalanceArgs {
        address receiverAddressSP;
        uint256 routerPlusPayloadId;
        uint256 amountReceivedInterimAsset;
        uint256[][] newAmounts;
        uint256[][] newOutputAmounts;
        LiqRequest[][] liqRequests;
    }

    struct CompleteCrossChainRebalanceLocalVars {
        uint256 balanceOfInterim;
        IERC20 interimAsset;
        uint256 amountToDeposit;
        bytes rebalanceToCallData;
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL VIEW FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @notice returns the call data for a cross-chain rebalance
    /// @param receiverAddressSP_ The address of the receiver
    /// @param routerPlusPayloadId_ The router plus payload id
    /// @return data_ The XChainRebalanceData struct
    function getXChainRebalanceCallData(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_
    )
        external
        view
        returns (XChainRebalanceData memory);

    /// @notice returns the decoded call data for a cross-chain rebalance
    /// @param receiverAddressSP_ The address of the receiver
    /// @param routerPlusPayloadId_ The router plus payload id
    /// @return D The DecodedRouterPlusRebalanceCallData struct
    function decodeXChainRebalanceCallData(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_
    )
        external
        view
        returns (DecodedRouterPlusRebalanceCallData memory D);

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @dev only callable by router plus
    /// @param receiverAddressSP_ The address of the receiver
    /// @param routerPlusPayloadId_ The router plus payload id
    /// @param data_ The XChainRebalanceData struct
    function setXChainRebalanceCallData(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_,
        XChainRebalanceData memory data_
    )
        external;

    /// @notice completes the rebalance process for positions on different chains
    /// @param args_ The arguments of the rebalance
    /// @return rebalanceSuccessful Whether the rebalance was successful
    function completeCrossChainRebalance(CompleteCrossChainRebalanceArgs memory args_)
        external
        payable
        returns (bool rebalanceSuccessful);

    /// @notice allows the receiver / disputer to protect against malicious processors
    /// @param finalPayloadId_ is the unique identifier of the refund
    function disputeRefund(uint256 finalPayloadId_) external;

    /// @notice allows the rescuer to propose a new refund amount after a successful dispute
    /// @param finalPayloadId_ is the unique identifier of the refund
    /// @param refundAmount_ is the new refund amount proposed
    function proposeRefund(uint256 finalPayloadId_, uint256 refundAmount_) external;

    /// @notice allows the user to claim their refund post the dispute period
    /// @param finalPayloadId_ is the unique identifier of the refund
    function finalizeRefund(uint256 finalPayloadId_) external;
}
