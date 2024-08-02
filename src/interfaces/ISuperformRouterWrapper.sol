// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface ISuperformRouterWrapper {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown when the deadline for a transaction has expired
    error EXPIRED();

    /// @notice thrown when an authorization has already been used
    error AUTHORIZATION_USED();

    /// @notice thrown when an invalid authorization is provided
    error INVALID_AUTHORIZATION();

    /// @notice thrown when a non-processor attempts to call a processor-only function
    error NOT_ROUTER_WRAPPER_PROCESSOR();

    /// @notice thrown when an invalid redeem selector is provided
    error INVALID_REDEEM_SELECTOR();

    /// @notice thrown when an invalid deposit selector is provided
    error INVALID_DEPOSIT_SELECTOR();

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

    /// @notice emitted when a cross-chain rebalance fails
    /// @param receiver The address that was to receive the rebalanced position
    /// @param firstStepLastCSRPayloadId The ID of the last payload in the first step of the rebalance
    event XChainRebalanceFailed(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    /// @notice emitted when a cross-chain rebalance is completed
    /// @param receiver The address receiving the rebalanced position
    /// @param firstStepLastCSRPayloadId The ID of the last payload in the first step of the rebalance
    event XChainRebalanceComplete(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    /// @notice emitted when a withdrawal is completed
    /// @param receiver The address receiving the withdrawn tokens
    /// @param id The ID of the position withdrawn from
    /// @param amount The amount of tokens withdrawn
    event WithdrawCompleted(address indexed receiver, uint256 indexed id, uint256 amount);

    /// @notice emitted when multiple withdrawals are completed
    /// @param receiver The address receiving the withdrawn tokens
    /// @param ids The IDs of the positions withdrawn from
    /// @param amounts The amounts of tokens withdrawn from each position
    event WithdrawMultiCompleted(address indexed receiver, uint256[] ids, uint256[] amounts);

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

    struct RebalanceMultiPositionsSyncArgs {
        uint256[] ids;
        uint256[] sharesToRedeem;
        uint256 previewRedeemAmount;
        address interimAsset;
        uint256 slippage;
        address receiverAddressSP;
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

    enum Actions {
        DEPOSIT,
        WITHDRAWAL
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @notice rebalances a single SuperPosition synchronously
    /// @dev Not to be used for multi-vault rebalances
    /// @param id_ The superform ID to redeem from
    /// @param sharesToRedeem_ The amount of superform shares to redeem
    /// @param previewRedeemAmount_ The amount of asset to receive after redeeming
    /// @param vaultAsset_ The asset to receive after redeeming
    /// @param slippage_ The slippage to allow for the rebalance
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param callData_ The encoded superform router request
    /// @param rebalanceCallData_ The encoded superform router request for the rebalance
    function rebalanceSinglePosition(
        uint256 id_,
        uint256 sharesToRedeem_,
        uint256 previewRedeemAmount_,
        address vaultAsset_,
        uint256 slippage_,
        address receiverAddressSP_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_,
        bool smartWallet_
    )
        external
        payable;

    /// @notice rebalances multiple SuperPositions synchronously
    /// @param args The arguments for rebalancing multiple positions
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs memory args) external payable;

    /// @notice initiates the rebalance process for a position on a different chain
    /// @param id_ The superform ID to redeem from
    /// @param sharesToRedeem_ The amount of superform shares to redeem
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param interimAsset_ The asset to receive on the other chain
    /// @param finalizeSlippage_ The slippage to allow for the finalize step
    /// @param expectedAmountInterimAsset_ The expected amount of interim asset to receive
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param callData_ The encoded superform router request
    /// @param rebalanceCallData_ The encoded superform router request for the rebalance
    function startCrossChainRebalance(
        uint256 id_,
        uint256 sharesToRedeem_,
        address receiverAddressSP_,
        address interimAsset_,
        uint256 finalizeSlippage_,
        uint256 expectedAmountInterimAsset_,
        bool smartWallet_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        payable;

    /// @notice initiates the rebalance process for multiple positions on different chains
    /// @dev TODO: validate interimAsset is final asset of the entire callData_
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

    /// @notice allows gasless transactions for token deposits
    /// @dev user needs to set infinite allowance of assets to wrapper for smooth UX
    /// @param asset_ The ERC20 asset to deposit
    /// @param amount_ The ERC20 amount to deposit
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param callData_ The encoded superform router deposit request
    /// @param deadline_ The deadline for the authorization
    /// @param nonce_ The nonce for the authorization
    /// @param signature_ The signature for the authorization
    function depositWithSignature(
        address asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_,
        uint256 deadline_,
        bytes32 nonce_,
        bytes memory signature_
    )
        external;

    /// @notice completes the disbursement process
    /// @param csrAckPayloadId_ The payload ID to complete the disbursement
    function finalizeDisbursement(uint256 csrAckPayloadId_) external;

    /// @notice completes multiple disbursements in a batch
    /// @param csrAckPayloadIds_ The payload IDs to complete the disbursements
    function finalizeBatchDisbursement(uint256[] calldata csrAckPayloadIds_) external;

    /// @notice withdraws from a single SuperPosition
    /// @dev TODO: decide if needed and implement cross-chain functionality
    /// @param id_ the ID of the position to withdraw from
    /// @param amount_ The amount to withdraw
    /// @param receiverAddressSP_ The receiver of the withdrawn tokens
    /// @param callData_ The encoded superform router withdrawal request
    function withdrawSinglePosition(
        uint256 id_,
        uint256 amount_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable;

    /// @notice withdraws from multiple SuperPositions
    /// @dev TODO: decide if needed and implement cross-chain functionality
    /// @param ids_ The IDs of the positions to withdraw from
    /// @param amounts_ The amounts to withdraw from each position
    /// @param receiverAddressSP_ The receiver of the withdrawn tokens
    /// @param callData_ The encoded superform router withdrawal request
    function withdrawMultiPositions(
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable;
}
