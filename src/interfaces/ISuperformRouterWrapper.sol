// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface ISuperformRouterWrapper {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown when a non-processor attempts to call a processor-only function
    error NOT_ROUTER_WRAPPER_PROCESSOR();

    /// @notice thrown when an invalid rebalance from selector is provided
    error INVALID_REBALANCE_FROM_SELECTOR();

    /// @notice thrown when an invalid rebalance to selector is provided
    error INVALID_REBALANCE_TO_SELECTOR();

    /// @notice thrown if the interimToken is different than expected
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN();

    /// @notice thrown if the liqDstChainId is different than expected
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN();

    /// @notice thrown if the interimToken is different than expected in the array
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();

    /// @notice thrown if the liqDstChainId is different than expected in the array
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();

    /// @notice thrown if the receiver address is invalid (not the wrapper)
    error REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();

    /// @notice thrown when the refund proposer is invalid
    error INVALID_PROPOSER();

    /// @notice thrown when the refund payload is invalid
    error INVALID_REFUND_DATA();

    /// @notice thrown when refund is already proposed
    error REFUND_ALREADY_PROPOSED();

    /// @notice thrown if the refund is still in dispute phase
    error IN_DISPUTE_PHASE();

    /// @notice thrown if msg.value is lower than the required fee
    error INVALID_FEE();

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    /// @notice emitted when a single position rebalance is completed
    /// @param receiver The address receiving the rebalanced position
    /// @param id The ID of the rebalanced position
    /// @param amount The amount of tokens rebalanced
    /// @param smartWallet Whether a smart wallet was used
    event RebalanceSyncCompleted(address indexed receiver, uint256 indexed id, uint256 amount, bool smartWallet);

    /// @notice emitted when multiple positions are rebalanced
    /// @param receiver The address receiving the rebalanced positions
    /// @param ids The IDs of the rebalanced positions
    /// @param amounts The amounts of tokens rebalanced for each position
    /// @param smartWallet Whether a smart wallet was used
    event RebalanceMultiSyncCompleted(address indexed receiver, uint256[] ids, uint256[] amounts, bool smartWallet);

    /// @notice emitted when a cross-chain rebalance is initiated
    /// @param receiver The address receiving the rebalanced position
    /// @param id The ID of the position being rebalanced
    /// @param amount The amount of tokens being rebalanced
    /// @param smartWallet Whether a smart wallet is being used
    /// @param interimAsset The address of the interim asset used in the cross-chain transfer
    /// @param finalizeSlippage The slippage tolerance for the finalization step
    /// @param expectedAmountInterimAsset The expected amount of interim asset to be received
    event XChainRebalanceInitiated(
        address indexed receiver,
        uint256 indexed id,
        uint256 amount,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset
    );

    /// @notice emitted when multiple cross-chain rebalances are initiated
    /// @param receiver The address receiving the rebalanced positions
    /// @param ids The IDs of the positions being rebalanced
    /// @param amounts The amounts of tokens being rebalanced for each position
    /// @param smartWallet Whether a smart wallet is being used
    /// @param interimAsset The address of the interim asset used in the cross-chain transfer
    /// @param finalizeSlippage The slippage tolerance for the finalization step
    /// @param expectedAmountInterimAsset The expected amount of interim asset to be received
    event XChainRebalanceMultiInitiated(
        address indexed receiver,
        uint256[] ids,
        uint256[] amounts,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset
    );

    /// @notice emitted when a cross-chain rebalance is completed
    /// @param receiver The address receiving the rebalanced position
    /// @param firstStepLastCSRPayloadId The ID of the last payload in the first step of the rebalance
    event XChainRebalanceComplete(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    /// @notice emitted when a deposit from an ERC4626 vault is completed
    /// @param receiver The address receiving the deposited tokens
    /// @param vault The address of the ERC4626 vault
    event Deposit4626Completed(address indexed receiver, address indexed vault);

    /// @notice emitted when a deposit is completed
    /// @param receiver The address receiving the deposited tokens
    /// @param smartWallet Whether a smart wallet was used
    /// @param meta Whether the deposit was a meta-transaction
    event DepositCompleted(address indexed receiver, bool smartWallet, bool meta);

    /// @notice emitted when a disbursement is completed
    /// @param receiver The address receiving the disbursed tokens
    /// @param payloadId The ID of the disbursement payload
    event DisbursementCompleted(address indexed receiver, uint256 indexed payloadId);

    /// @notice emitted when a new refund is created
    /// @param lastPayloadId is the unique identifier for the payload
    /// @param refundReceiver is the address of the user who'll receiver the refund
    /// @param refundToken is the token to be refunded
    /// @param refundAmount is the new refund amount
    event RefundInitiated(
        uint256 indexed lastPayloadId, address indexed refundReceiver, address refundToken, uint256 refundAmount
    );

    /// @notice emitted when an existing refund got disputed
    /// @param lastPayloadId is the unique identifier for the payload
    /// @param disputer is the address of the user who disputed the refund
    event RefundDisputed(uint256 indexed lastPayloadId, address indexed disputer);

    /// @notice emitted when a new refund amount is proposed
    /// @param lastPayloadId is the unique identifier for the payload
    /// @param newRefundAmount is the new refund amount proposed
    event NewRefundAmountProposed(uint256 indexed lastPayloadId, uint256 indexed newRefundAmount);

    /// @notice emitted when a refund is complete
    /// @param lastPayloadId is the unique identifier for the payload
    /// @param caller is the address of the user who called the function
    event RefundCompleted(uint256 indexed lastPayloadId, address indexed caller);

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

    struct XChainRebalanceData {
        bytes rebalanceCalldata;
        bool smartWallet;
        address interimAsset;
        uint256 slippage;
        uint256 expectedAmountInterimAsset;
    }

    struct RebalanceSinglePositionSyncArgs {
        uint256 id;
        uint256 sharesToRedeem;
        uint256 previewRedeemAmount;
        uint256 rebalanceFromMsgValue;
        uint256 rebalanceToMsgValue;
        address interimAsset;
        uint256 slippage;
        address receiverAddressSP;
        bool smartWallet;
        bytes callData;
        bytes rebalanceCallData;
    }

    struct RebalanceMultiPositionsSyncArgs {
        uint256[] ids;
        uint256[] sharesToRedeem;
        uint256 previewRedeemAmount;
        uint256 rebalanceFromMsgValue;
        uint256 rebalanceToMsgValue;
        address interimAsset;
        uint256 slippage;
        address receiverAddressSP;
        bool smartWallet;
        bytes callData;
        bytes rebalanceCallData;
    }

    struct RebalancePositionsSyncArgs {
        Actions action;
        uint256 previewRedeemAmount;
        address asset;
        uint256 slippage;
        uint256 rebalanceFromMsgValue;
        uint256 rebalanceToMsgValue;
        address receiverAddressSP;
        bool smartWallet;
    }

    struct InitiateXChainRebalanceArgs {
        uint256 id;
        uint256 sharesToRedeem;
        address receiverAddressSP;
        address interimAsset;
        uint256 finalizeSlippage;
        uint256 expectedAmountInterimAsset;
        bool smartWallet;
        bytes callData;
        bytes rebalanceCallData;
    }

    struct InitiateXChainRebalanceMultiArgs {
        uint256[] ids;
        uint256[] sharesToRedeem;
        address receiverAddressSP;
        address interimAsset;
        uint256 finalizeSlippage;
        uint256 expectedAmountInterimAsset;
        bool smartWallet;
        bytes callData;
        bytes rebalanceCallData;
    }

    struct Refund {
        address receiver;
        address interimToken;
        uint256 amount;
        uint256 proposedTime;
    }

    enum Actions {
        DEPOSIT,
        REBALANCE_FROM_SINGLE,
        REBALANCE_FROM_MULTI,
        REBALANCE_X_CHAIN_FROM_SINGLE,
        REBALANCE_X_CHAIN_FROM_MULTI,
        REBALANCE_TO
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @notice rebalances a single SuperPosition synchronously
    /// @notice interim asset and receiverAddressSP must be set. In non smart contract wallet rebalances,
    /// receiverAddressSP is only used for refunds
    /// @param args The arguments for rebalancing single positions
    function rebalanceSinglePosition(RebalanceSinglePositionSyncArgs calldata args) external payable;

    /// @notice rebalances multiple SuperPositions synchronously
    /// @notice interim asset and receiverAddressSP must be set. In non smart contract wallet rebalances,
    /// receiverAddressSP is only used for refunds
    /// @notice receiverAddressSP of rebalanceCallData must be the address of the wrapper for smart wallets
    /// @notice for normal deposits receiverAddressSP is the users' specified receiverAddressSP
    /// @param args The arguments for rebalancing multiple positions
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs calldata args) external payable;

    /// @notice initiates the rebalance process for a position on a different chain
    /// @param args The arguments for initiating cross-chain rebalance for single positions
    function startCrossChainRebalance(InitiateXChainRebalanceArgs calldata args) external payable;

    /// @notice initiates the rebalance process for multiple positions on different chains
    /// @param args The arguments for initiating cross-chain rebalance for multiple positions
    function startCrossChainRebalanceMulti(InitiateXChainRebalanceMultiArgs memory args) external payable;

    /// @notice completes the rebalance process for positions on different chains
    /// @dev TODO: determine handling of interim asset transfer if slippage check fails
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param firstStepLastCSRPayloadId_ The first step payload ID
    /// @param amountReceivedInterimAsset_ The amount of interim asset received
    /// @return rebalanceSuccessful Whether the rebalance was successful
    function completeCrossChainRebalance(
        address receiverAddressSP_,
        uint256 firstStepLastCSRPayloadId_,
        uint256 amountReceivedInterimAsset_
    )
        external
        payable
        returns (bool rebalanceSuccessful);

    /// @notice deposits ERC4626 vault shares into superform
    /// @param vault_ The ERC4626 vault to redeem from
    /// @param amount_ The ERC4626 vault share amount to redeem
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param callData_ The encoded superform router request
    function deposit4626(
        address vault_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable;

    /// @notice deposits tokens into superform
    /// @dev should only allow a single asset to be deposited
    /// @param asset_ The ERC20 asset to deposit
    /// @param amount_ The ERC20 amount to deposit
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param callData_ The encoded superform router deposit request
    function deposit(
        IERC20 asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable;

    /// @notice completes the disbursement process
    /// @param csrAckPayloadId_ The payload ID to complete the disbursement
    function finalizeDisbursement(uint256 csrAckPayloadId_) external;

    /// @notice completes multiple disbursements in a batch
    /// @param csrAckPayloadIds_ The payload IDs to complete the disbursements
    function finalizeBatchDisbursement(uint256[] calldata csrAckPayloadIds_) external;

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
