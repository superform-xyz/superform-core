// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface ISuperformRouterWrapper {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    error EXPIRED();
    error AUTHORIZATION_USED();
    error INVALID_AUTHORIZATION();
    error NOT_ROUTER_WRAPPER_PROCESSOR();
    error INVALID_REDEEM_SELECTOR();
    error INVALID_DEPOSIT_SELECTOR();

    //////////////////////////////////////////////////////////////
    //                       EVENTS                             //
    //////////////////////////////////////////////////////////////

    event RebalanceSyncCompleted(address indexed receiver, uint256 indexed id, uint256 amount, bool smartWallet);

    event RebalanceMultiSyncCompleted(address indexed receiver, uint256[] ids, uint256[] amounts, bool smartWallet);

    event XChainRebalanceInitiated(
        address indexed receiver,
        uint256 indexed id,
        uint256 amount,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset
    );

    event XChainRebalanceMultiInitiated(
        address indexed receiver,
        uint256[] ids,
        uint256[] amounts,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset
    );

    event XChainRebalanceFailed(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    event XChainRebalanceComplete(address indexed receiver, uint256 indexed firstStepLastCSRPayloadId);

    event WithdrawCompleted(address indexed receiver, uint256 indexed id, uint256 amount);

    event WithdrawMultiCompleted(address indexed receiver, uint256[] ids, uint256[] amounts);

    event Deposit4626Completed(address indexed receiver, address indexed vault);

    event DepositCompleted(address indexed receiver, bool smartWallet, bool meta);

    event DisbursementCompleted(address indexed receiver, uint256 indexed payloadId);

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

    /// @dev helps user rebalance a single SuperPosition in a synchronous way
    /// @dev note: this is not to be used by multi vault rebalances
    /// @param id_ the superform id to redeem from
    /// @param sharesToRedeem_ the amount of superform shares to redeem
    /// @param previewRedeemAmount_ the amount of asset to receive after redeeming
    /// @param vaultAsset_ the asset to receive after redeeming
    /// @param slippage_ the slippage to allow for the rebalance
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router request
    /// @param rebalanceCallData_ the encoded superform router request for the rebalance
    function rebalancePositionsSync(
        uint256 id_,
        uint256 sharesToRedeem_,
        uint256 previewRedeemAmount_,
        address vaultAsset_,
        uint256 slippage_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_,
        bytes calldata rebalanceCallData_
    )
        external
        payable;

    /// @dev batch version of the function above
    /// @param args the args to rebalance (similar to the function above)
    function rebalanceMultiPositionsSync(RebalanceMultiPositionsSyncArgs memory args) external payable;

    /// @dev initiates the rebalance process for when the vault to redeem from is on a different chain
    /// @param id_ the superform id to redeem from
    /// @param sharesToRedeem_ the amount of superform shares to redeem
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param interimAsset_ the asset to receive on the other chain
    /// @param finalizeSlippage_ the slippage to allow for the finalize step
    /// @param expectedAmountInterimAsset_ the expected amount of interim asset to receive
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router request
    /// @param rebalanceCallData_ the encoded superform router request for the rebalance
    function initiateXChainRebalance(
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

    /// @dev batch version of the function above
    /// @dev TODO how to validate interimAsset is final asset of the entire callData_ (and should we check
    /// expectedAmountInterimAsset on finalize)
    /// @param args the args to rebalance (similar to the function above)
    function initiateXChainRebalanceMulti(InitiateXChainRebalanceMultiArgs memory args) external payable;

    /// @dev completes the rebalance process for when the vault to redeem from is on a different chain
    /// @notice rebalanceCalldata can contain multiple destinations or vaults, but external asset remains one
    /// @dev TODO should we transfer the interim asset in case the slippage check fails? or how do we deal with this?
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param firstStepLastCSRPayloadId_ the first step payload id
    /// @param amountReceivedInterimAsset_ the amount of interim asset received
    function finalizeXChainRebalance(
        address receiverAddressSP_,
        uint256 firstStepLastCSRPayloadId_,
        uint256 amountReceivedInterimAsset_
    )
        external
        payable
        returns (bool rebalanceSuccessful);

    /// NOTE: add function for same chain action
    /// NOTE: just 4626 shares
    /// @dev helps user deposit 4626 vault shares into superform
    /// @dev this helps with goal "2 Entering Superform via any 4626 share in one step by transfering the share to the
    /// specific superform"
    /// @param vault_ the 4626 vault to redeem from
    /// @param amount_ the 4626 vault share amount to redeem
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router request
    function deposit4626(
        address vault_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable;

    /// @dev helps user deposit into superform
    /// @dev should only allow a single asset to be deposited (because this is similar to a normal deposit)
    /// @dev adds smart wallet support
    /// @dev this covers the goal "3 Providing better compatibility with smart contract wallets such as coinbase smart
    /// wallet"
    /// @param asset_ the ERC20 asset to deposit
    /// @param amount_ the ERC20 amount to deposit
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router deposit request
    function deposit(
        IERC20 asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata callData_
    )
        external
        payable;

    /// @dev allows gasless transactions for the function above
    /// @notice misses logic to covert a portion of amount to native tokens for the keeper
    /// @dev this helps with goal "4 Allow for gasless transactions where tx costs are deducted from funding tokens (or
    /// from SuperPositions) OR subsidized by Superform team."
    /// @dev user needs to set infinite allowance of assets to wrapper to allow this in smooth ux
    /// @param asset_ the ERC20 asset to deposit
    /// @param amount_ the ERC20 amount to deposit
    /// @param receiverAddressSP_ the receiver of the superform shares
    /// @param smartWallet_ whether to use smart wallet or not
    /// @param callData_ the encoded superform router deposit request
    /// @param deadline_ the deadline for the authorization
    /// @param nonce_ the nonce for the authorization
    /// @param signature_ the signature for the authorization
    function metaDeposit(
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

    /// @dev this is callback payload id
    /// @dev this covers the goal "3 Providing better compatibility with smart contract wallets such as coinbase smart
    /// wallet"
    /// @param csrAckPayloadId_ the payload id to complete the disbursement
    function completeDisbursement(uint256 csrAckPayloadId_) external;

    /// @dev batch version of the function above
    /// @param csrAckPayloadIds_ the payload ids to complete the disbursement
    function batchCompleteDisbursement(uint256[] calldata csrAckPayloadIds_) external;

    /// @dev helps user exit SuperPositions
    /// @dev TODO decide if needed
    /// @dev TODO can decode callData to obtain dstChains and message wrapper accordingly to allow rebalances in dsts
    /// (advanced)
    function withdraw(
        uint256 id_,
        uint256 amount_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable;

    /// @dev batch version of the function above
    /// @dev TODO decide if needed
    function withdrawMulti(
        uint256[] calldata ids_,
        uint256[] calldata amounts_,
        address receiverAddressSP_,
        bytes calldata callData_
    )
        external
        payable;
}
