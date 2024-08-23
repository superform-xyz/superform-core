// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseSuperformRouterPlus, IERC20 } from "./IBaseSuperformRouterPlus.sol";

interface ISuperformRouterPlus is IBaseSuperformRouterPlus {
    //////////////////////////////////////////////////////////////
    //                       ERRORS                             //
    //////////////////////////////////////////////////////////////

    /// @notice thrown when an invalid rebalance from selector is provided
    error INVALID_REBALANCE_FROM_SELECTOR();

    /// @notice thrown when an invalid deposit selector provided
    error INVALID_DEPOSIT_SELECTOR();

    /// @notice thrown if the interimToken is different than expected
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN();

    /// @notice thrown if the liqDstChainId is different than expected
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN();

    /// @notice thrown if the amounts to redeem differ
    error REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT();

    /// @notice thrown if the interimToken is different than expected in the array
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();

    /// @notice thrown if the liqDstChainId is different than expected in the array
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();

    /// @notice thrown if the amounts to redeem differ
    error REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();

    /// @notice thrown if the receiver address is invalid (not the router plus)
    error REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();

    /// @notice thrown if msg.value is lower than the required fee
    error INVALID_FEE();

    /// @notice thrown if rebalance to calldata is empty
    error EMPTY_REBALANCE_CALL_DATA();

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
    /// @param rebalanceToSelector The selector for the rebalance to function
    event XChainRebalanceInitiated(
        address indexed receiver,
        uint256 indexed id,
        uint256 amount,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset,
        bytes4 rebalanceToSelector
    );

    /// @notice emitted when multiple cross-chain rebalances are initiated
    /// @param receiver The address receiving the rebalanced positions
    /// @param ids The IDs of the positions being rebalanced
    /// @param amounts The amounts of tokens being rebalanced for each position
    /// @param smartWallet Whether a smart wallet is being used
    /// @param interimAsset The address of the interim asset used in the cross-chain transfer
    /// @param finalizeSlippage The slippage tolerance for the finalization step
    /// @param expectedAmountInterimAsset The expected amount of interim asset to be received
    /// @param rebalanceToSelector The selector for the rebalance to function
    event XChainRebalanceMultiInitiated(
        address indexed receiver,
        uint256[] ids,
        uint256[] amounts,
        bool smartWallet,
        address interimAsset,
        uint256 finalizeSlippage,
        uint256 expectedAmountInterimAsset,
        bytes4 rebalanceToSelector
    );

    /// @notice emitted when a deposit from an ERC4626 vault is completed
    /// @param receiver The address receiving the deposited tokens
    /// @param vault The address of the ERC4626 vault
    event Deposit4626Completed(address indexed receiver, address indexed vault);

    /// @notice emitted when a deposit is completed
    /// @param receiver The address receiving the deposited tokens
    /// @param smartWallet Whether a smart wallet was used
    /// @param meta Whether the deposit was a meta-transaction
    event DepositCompleted(address indexed receiver, bool smartWallet, bool meta);
    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

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
        bytes rebalanceToAmbIds;
        bytes rebalanceToDstChainIds;
        bytes rebalanceToSfData;
        bytes4 rebalanceToSelector;
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
        bytes rebalanceToAmbIds;
        bytes rebalanceToDstChainIds;
        bytes rebalanceToSfData;
        bytes4 rebalanceToSelector;
    }

    struct RebalancePositionsSyncArgs {
        Actions action;
        uint256[] sharesToRedeem;
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
        bytes4 rebalanceToSelector;
        bytes callData;
        bytes rebalanceToAmbIds;
        bytes rebalanceToDstChainIds;
        bytes rebalanceToSfData;
    }

    struct InitiateXChainRebalanceMultiArgs {
        uint256[] ids;
        uint256[] sharesToRedeem;
        address receiverAddressSP;
        address interimAsset;
        uint256 finalizeSlippage;
        uint256 expectedAmountInterimAsset;
        bool smartWallet;
        bytes4 rebalanceToSelector;
        bytes callData;
        bytes rebalanceToAmbIds;
        bytes rebalanceToDstChainIds;
        bytes rebalanceToSfData;
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
    /// @notice receiverAddressSP of rebalanceCallData must be the address of the router plus for smart wallets
    /// @notice for normal deposits receiverAddressSP is the users' specified receiverAddressSP
    /// @param args The arguments for rebalancing multiple positions
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs calldata args) external payable;

    /// @notice initiates the rebalance process for a position on a different chain
    /// @param args The arguments for initiating cross-chain rebalance for single positions
    function startCrossChainRebalance(InitiateXChainRebalanceArgs calldata args) external payable;

    /// @notice initiates the rebalance process for multiple positions on different chains
    /// @param args The arguments for initiating cross-chain rebalance for multiple positions
    function startCrossChainRebalanceMulti(InitiateXChainRebalanceMultiArgs memory args) external payable;

    /// @notice deposits ERC4626 vault shares into superform
    /// @param vault_ The ERC4626 vault to redeem from
    /// @param amount_ The ERC4626 vault share amount to redeem
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param depositAmbIds_ The array of AMB bridge IDs for the deposit
    /// @param depositDstChainIds_ The array of destination chain IDs for the deposit
    /// @param depositSfData_ The array of superform data for the deposit
    /// @param depositSelector_ The selector for the deposit function
    function deposit4626(
        address vault_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata depositAmbIds_,
        bytes calldata depositDstChainIds_,
        bytes calldata depositSfData_,
        bytes4 depositSelector_
    )
        external
        payable;

    /// @notice deposits tokens into superform
    /// @dev should only allow a single asset to be deposited
    /// @param asset_ The ERC20 asset to deposit
    /// @param amount_ The ERC20 amount to deposit
    /// @param receiverAddressSP_ The receiver of the superform shares
    /// @param smartWallet_ Whether to use smart wallet or not
    /// @param depositAmbIds_ The array of AMB bridge IDs for the deposit
    /// @param depositDstChainIds_ The array of destination chain IDs for the deposit
    /// @param depositSfData_ The array of superform data for the deposit
    /// @param depositSelector_ The selector for the deposit function
    function deposit(
        IERC20 asset_,
        uint256 amount_,
        address receiverAddressSP_,
        bool smartWallet_,
        bytes calldata depositAmbIds_,
        bytes calldata depositDstChainIds_,
        bytes calldata depositSfData_,
        bytes4 depositSelector_
    )
        external
        payable;
}