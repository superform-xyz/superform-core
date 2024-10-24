// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { SuperPositions } from "src/SuperPositions.sol";
import { Error } from "src/libraries/Error.sol";
import { SingleVaultSFData, MultiVaultSFData } from "src/types/DataTypes.sol";
import {
    BaseSuperformRouterPlus,
    SingleDirectSingleVaultStateReq,
    SingleDirectMultiVaultStateReq,
    SingleXChainSingleVaultStateReq,
    SingleXChainMultiVaultStateReq,
    MultiDstMultiVaultStateReq,
    MultiDstSingleVaultStateReq
} from "src/router-plus/BaseSuperformRouterPlus.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import { ISuperformRouterPlus, IERC20 } from "src/interfaces/ISuperformRouterPlus.sol";
import { ISuperformRouterPlusAsync } from "src/interfaces/ISuperformRouterPlusAsync.sol";

/// @title SuperformRouterPlus
/// @dev Performs rebalances and deposits on the Superform platform
/// @author Zeropoint Labs
contract SuperformRouterPlus is ISuperformRouterPlus, BaseSuperformRouterPlus {
    using SafeERC20 for IERC20;

    uint256 public ROUTER_PLUS_PAYLOAD_ID;

    /// @dev Tolerance constant to account for tokens with rounding issues on transfer
    uint256 constant TOLERANCE_CONSTANT = 10 wei;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BaseSuperformRouterPlus(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformRouterPlus
    function rebalanceSinglePosition(RebalanceSinglePositionSyncArgs calldata args) external payable override {
        ///@notice when building the data to rebalance to it is important to carefuly calculate
        /// expectedAmountToReceivePostRebalanceFrom
        /// this is especially important in multi vault rebalance
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));
        address router = _getAddress(keccak256("SUPERFORM_ROUTER"));

        (uint256 balanceBefore, uint256 totalFee) = _beforeRebalanceChecks(
            args.interimAsset, args.receiverAddressSP, args.rebalanceFromMsgValue, args.rebalanceToMsgValue
        );

        /// @dev transfers a single superPosition to this contract and approves router
        _transferSuperPositions(superPositions, router, args.receiverAddressSP, args.id, args.sharesToRedeem);

        uint256[] memory sharesToRedeem = new uint256[](1);

        sharesToRedeem[0] = args.sharesToRedeem;

        _rebalancePositionsSync(
            router,
            RebalancePositionsSyncArgs(
                Actions.REBALANCE_FROM_SINGLE,
                sharesToRedeem,
                args.expectedAmountToReceivePostRebalanceFrom,
                args.interimAsset,
                args.slippage,
                args.rebalanceFromMsgValue,
                args.rebalanceToMsgValue,
                args.receiverAddressSP,
                balanceBefore
            ),
            args.callData,
            args.rebalanceToCallData
        );

        _refundUnusedAndResetApprovals(
            superPositions, router, args.interimAsset, args.receiverAddressSP, balanceBefore, totalFee
        );

        emit RebalanceSyncCompleted(args.receiverAddressSP, args.id, args.sharesToRedeem);
    }

    /// @inheritdoc ISuperformRouterPlus
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs calldata args) external payable override {
        ///@notice when building the data to rebalance to it is important to carefuly calculate
        /// expectedAmountToReceivePostRebalanceFrom
        /// this is especially important in multi vault rebalance

        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));
        address router = _getAddress(keccak256("SUPERFORM_ROUTER"));

        (uint256 balanceBefore, uint256 totalFee) = _beforeRebalanceChecks(
            args.interimAsset, args.receiverAddressSP, args.rebalanceFromMsgValue, args.rebalanceToMsgValue
        );

        if (args.ids.length != args.sharesToRedeem.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        /// @dev transfers multiple superPositions to this contract and approves router
        _transferBatchSuperPositions(superPositions, router, args.receiverAddressSP, args.ids, args.sharesToRedeem);

        _rebalancePositionsSync(
            router,
            RebalancePositionsSyncArgs(
                Actions.REBALANCE_FROM_MULTI,
                args.sharesToRedeem,
                args.expectedAmountToReceivePostRebalanceFrom,
                args.interimAsset,
                args.slippage,
                args.rebalanceFromMsgValue,
                args.rebalanceToMsgValue,
                args.receiverAddressSP,
                balanceBefore
            ),
            args.callData,
            args.rebalanceToCallData
        );

        _refundUnusedAndResetApprovals(
            superPositions, router, args.interimAsset, args.receiverAddressSP, balanceBefore, totalFee
        );

        emit RebalanceMultiSyncCompleted(args.receiverAddressSP, args.ids, args.sharesToRedeem);
    }

    /// @inheritdoc ISuperformRouterPlus
    function startCrossChainRebalance(InitiateXChainRebalanceArgs calldata args) external payable override {
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));
        address router = _getAddress(keccak256("SUPERFORM_ROUTER"));

        if (args.interimAsset == address(0) || args.receiverAddressSP == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (args.expectedAmountInterimAsset == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev transfers a single superPosition to this contract and approves router
        _transferSuperPositions(superPositions, router, args.receiverAddressSP, args.id, args.sharesToRedeem);

        /// @dev this can only be IBaseRouter.singleXChainSingleVaultWithdraw.selector due to the whitelist in
        /// BaseSuperformRouterPlus
        if (!whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_SINGLE][_parseSelectorMem(args.callData)]) {
            revert INVALID_REBALANCE_FROM_SELECTOR();
        }

        if (!whitelistedSelectors[Actions.DEPOSIT][args.rebalanceToSelector]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        /// @dev validate the call data
        SingleXChainSingleVaultStateReq memory req =
            abi.decode(_parseCallData(args.callData), (SingleXChainSingleVaultStateReq));

        if (req.superformData.liqRequest.token != args.interimAsset) {
            revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN();
        }

        if (req.superformData.liqRequest.liqDstChainId != CHAIN_ID) {
            revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN();
        }

        if (req.superformData.amount != args.sharesToRedeem) {
            revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT();
        }

        address ROUTER_PLUS_ASYNC = _getAddress(keccak256("SUPERFORM_ROUTER_PLUS_ASYNC"));

        if (req.superformData.receiverAddress != ROUTER_PLUS_ASYNC) {
            revert REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();
        }

        /// @dev send SPs to router
        /// @notice msg.value here is the sum of rebalanceFromMsgValue and rebalanceToMsgValue (to be executed later by
        /// the keeper)
        _callSuperformRouter(router, args.callData, msg.value);

        uint256 routerPlusPayloadId = ++ROUTER_PLUS_PAYLOAD_ID;

        ISuperformRouterPlusAsync(ROUTER_PLUS_ASYNC).setXChainRebalanceCallData(
            args.receiverAddressSP,
            routerPlusPayloadId,
            XChainRebalanceData({
                rebalanceSelector: args.rebalanceToSelector,
                interimAsset: args.interimAsset,
                slippage: args.finalizeSlippage,
                expectedAmountInterimAsset: args.expectedAmountInterimAsset,
                rebalanceToAmbIds: args.rebalanceToAmbIds,
                rebalanceToDstChainIds: args.rebalanceToDstChainIds,
                rebalanceToSfData: args.rebalanceToSfData
            })
        );

        emit XChainRebalanceInitiated(
            args.receiverAddressSP,
            routerPlusPayloadId,
            args.id,
            args.sharesToRedeem,
            args.interimAsset,
            args.finalizeSlippage,
            args.expectedAmountInterimAsset,
            args.rebalanceToSelector
        );
    }

    /// @inheritdoc ISuperformRouterPlus
    function startCrossChainRebalanceMulti(InitiateXChainRebalanceMultiArgs calldata args) external payable override {
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));
        address router = _getAddress(keccak256("SUPERFORM_ROUTER"));

        if (args.ids.length != args.sharesToRedeem.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        if (args.interimAsset == address(0) || args.receiverAddressSP == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (args.expectedAmountInterimAsset == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev transfers multiple superPositions to this contract and approves router
        _transferBatchSuperPositions(superPositions, router, args.receiverAddressSP, args.ids, args.sharesToRedeem);

        /// @dev validate the call data
        bytes4 selector = _parseSelectorMem(args.callData);

        if (!whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_MULTI][selector]) {
            revert INVALID_REBALANCE_FROM_SELECTOR();
        }

        address ROUTER_PLUS_ASYNC = _getAddress(keccak256("SUPERFORM_ROUTER_PLUS_ASYNC"));

        if (selector == IBaseRouter.singleXChainMultiVaultWithdraw.selector) {
            SingleXChainMultiVaultStateReq memory req =
                abi.decode(_parseCallData(args.callData), (SingleXChainMultiVaultStateReq));

            uint256 len = req.superformsData.liqRequests.length;

            for (uint256 i; i < len; ++i) {
                // Validate that the token and chainId is equal in all indexes
                if (req.superformsData.liqRequests[i].token != args.interimAsset) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();
                }
                if (req.superformsData.liqRequests[i].liqDstChainId != CHAIN_ID) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();
                }
                if (req.superformsData.amounts[i] != args.sharesToRedeem[i]) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                }
            }

            if (req.superformsData.receiverAddress != ROUTER_PLUS_ASYNC) {
                revert REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();
            }
        } else if (selector == IBaseRouter.multiDstMultiVaultWithdraw.selector) {
            MultiDstMultiVaultStateReq memory req =
                abi.decode(_parseCallData(args.callData), (MultiDstMultiVaultStateReq));

            uint256 len = req.superformsData.length;

            uint256 count;
            for (uint256 i; i < len; ++i) {
                uint256 len2 = req.superformsData[i].liqRequests.length;

                for (uint256 j; j < len2; ++j) {
                    // Validate that the token and chainId is equal in all indexes
                    if (req.superformsData[i].liqRequests[j].token != args.interimAsset) {
                        revert REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();
                    }
                    if (req.superformsData[i].liqRequests[j].liqDstChainId != CHAIN_ID) {
                        revert REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();
                    }

                    /// @dev WARNING: for multiDst all shares are organized in a single array
                    /// array starts in the first destination with all the shares
                    /// then it continues through all destinations with the same process
                    if (req.superformsData[i].amounts[j] != args.sharesToRedeem[count]) {
                        revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                    }
                    ++count;
                }

                if (req.superformsData[i].receiverAddress != ROUTER_PLUS_ASYNC) {
                    revert REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();
                }
            }
        } else if (selector == IBaseRouter.multiDstSingleVaultWithdraw.selector) {
            MultiDstSingleVaultStateReq memory req =
                abi.decode(_parseCallData(args.callData), (MultiDstSingleVaultStateReq));

            uint256 len = req.superformsData.length;

            for (uint256 i; i < len; ++i) {
                // Validate that the token and chainId is equal in all indexes
                if (req.superformsData[i].liqRequest.token != args.interimAsset) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();
                }
                if (req.superformsData[i].liqRequest.liqDstChainId != CHAIN_ID) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();
                }

                /// @dev WARNING: for multiDst all shares are organized in a single array
                /// array starts in the first destination with all the shares
                /// then it continues through all destinations with the same process
                if (req.superformsData[i].amount != args.sharesToRedeem[i]) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                }

                if (req.superformsData[i].receiverAddress != ROUTER_PLUS_ASYNC) {
                    revert REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();
                }
            }
        }

        /// @dev send SPs to router
        _callSuperformRouter(router, args.callData, msg.value);

        if (!whitelistedSelectors[Actions.DEPOSIT][args.rebalanceToSelector]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        uint256 routerPlusPayloadId = ++ROUTER_PLUS_PAYLOAD_ID;

        /// @dev in multiDst multiple payloads ids will be generated on source chain
        ISuperformRouterPlusAsync(ROUTER_PLUS_ASYNC).setXChainRebalanceCallData(
            args.receiverAddressSP,
            routerPlusPayloadId,
            XChainRebalanceData({
                rebalanceSelector: args.rebalanceToSelector,
                interimAsset: args.interimAsset,
                slippage: args.finalizeSlippage,
                expectedAmountInterimAsset: args.expectedAmountInterimAsset,
                rebalanceToAmbIds: args.rebalanceToAmbIds,
                rebalanceToDstChainIds: args.rebalanceToDstChainIds,
                rebalanceToSfData: args.rebalanceToSfData
            })
        );

        emit XChainRebalanceMultiInitiated(
            args.receiverAddressSP,
            routerPlusPayloadId,
            args.ids,
            args.sharesToRedeem,
            args.interimAsset,
            args.finalizeSlippage,
            args.expectedAmountInterimAsset,
            args.rebalanceToSelector
        );
    }

    /// @inheritdoc ISuperformRouterPlus
    function deposit4626(address vault_, Deposit4626Args calldata args) external payable override {
        _transferERC20In(IERC20(vault_), args.receiverAddressSP, args.amount);
        IERC4626 vault = IERC4626(vault_);
        address assetAdr = vault.asset();
        IERC20 asset = IERC20(assetAdr);

        uint256 balanceBefore = asset.balanceOf(address(this));

        uint256 amountRedeemed = _redeemShare(vault, assetAdr, args.amount, args.expectedOutputAmount, args.maxSlippage);

        if (!whitelistedSelectors[Actions.DEPOSIT][_parseSelectorMem(args.depositCallData)]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        address router = _getAddress(keccak256("SUPERFORM_ROUTER"));
        _deposit(router, asset, amountRedeemed, msg.value, args.depositCallData);

        _tokenRefunds(router, assetAdr, args.receiverAddressSP, balanceBefore);

        emit Deposit4626Completed(args.receiverAddressSP, vault_);
    }

    /// @inheritdoc ISuperformRouterPlus
    function forwardDustToPaymaster(address token_) external override {
        if (token_ == address(0)) revert Error.ZERO_ADDRESS();

        address paymaster = _getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(token_);

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit RouterPlusDustForwardedToPaymaster(token_, dust);
        }
    }

    //////////////////////////////////////////////////////////////
    //                   INTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function _rebalancePositionsSync(
        address router_,
        RebalancePositionsSyncArgs memory args,
        bytes calldata callData,
        bytes calldata rebalanceToCallData
    )
        internal
    {
        IERC20 interimAsset = IERC20(args.interimAsset);

        /// @dev validate the call dataREBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT
        if (!whitelistedSelectors[args.action][_parseSelectorMem(callData)]) {
            revert INVALID_REBALANCE_FROM_SELECTOR();
        }

        if (args.action == Actions.REBALANCE_FROM_SINGLE) {
            SingleDirectSingleVaultStateReq memory req =
                abi.decode(_parseCallData(callData), (SingleDirectSingleVaultStateReq));

            if (req.superformData.liqRequest.token != args.interimAsset) {
                revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN();
            }
            if (req.superformData.liqRequest.liqDstChainId != CHAIN_ID) {
                revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN();
            }
            if (req.superformData.amount != args.sharesToRedeem[0]) {
                revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT();
            }
            if (req.superformData.receiverAddress != address(this)) {
                revert REBALANCE_SINGLE_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS();
            }
        } else {
            /// then must be Actions.REBALANCE_FROM_MULTI
            SingleDirectMultiVaultStateReq memory req =
                abi.decode(_parseCallData(callData), (SingleDirectMultiVaultStateReq));
            uint256 len = req.superformData.liqRequests.length;

            for (uint256 i; i < len; ++i) {
                // Validate that the token and chainId is equal in all indexes
                if (req.superformData.liqRequests[i].token != args.interimAsset) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();
                }
                if (req.superformData.liqRequests[i].liqDstChainId != CHAIN_ID) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();
                }
                if (req.superformData.amounts[i] != args.sharesToRedeem[i]) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                }
                if (req.superformData.receiverAddress != address(this)) {
                    revert REBALANCE_MULTI_POSITIONS_UNEXPECTED_RECEIVER_ADDRESS();
                }
            }
        }
        /// @dev send SPs to router
        _callSuperformRouter(router_, callData, args.rebalanceFromMsgValue);

        uint256 amountToDeposit = interimAsset.balanceOf(address(this)) - args.balanceBefore;

        if (amountToDeposit == 0) revert Error.ZERO_AMOUNT();

        if (
            ENTIRE_SLIPPAGE * amountToDeposit
                < ((args.expectedAmountToReceivePostRebalanceFrom * (ENTIRE_SLIPPAGE - args.slippage)))
        ) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        /// @dev step 3: rebalance into a new superform with rebalanceCallData
        if (!whitelistedSelectors[Actions.DEPOSIT][_parseSelectorMem(rebalanceToCallData)]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        _deposit(router_, interimAsset, amountToDeposit, args.rebalanceToMsgValue, rebalanceToCallData);
    }

    function _transferSuperPositions(
        address superPositions_,
        address router_,
        address user_,
        uint256 id_,
        uint256 amount_
    )
        internal
    {
        SuperPositions(superPositions_).safeTransferFrom(user_, address(this), id_, amount_, "");
        SuperPositions(superPositions_).setApprovalForOne(router_, id_, amount_);
    }

    function _transferBatchSuperPositions(
        address superPositions_,
        address router_,
        address user_,
        uint256[] memory ids_,
        uint256[] memory amounts_
    )
        internal
    {
        SuperPositions(superPositions_).safeBatchTransferFrom(user_, address(this), ids_, amounts_, "");
        SuperPositions(superPositions_).setApprovalForAll(router_, true);
    }

    function _transferERC20In(IERC20 erc20_, address user_, uint256 amount_) internal {
        erc20_.safeTransferFrom(user_, address(this), amount_);
    }

    function _redeemShare(
        IERC4626 vault_,
        address assetAdr_,
        uint256 amountToRedeem_,
        uint256 expectedOutputAmount_,
        uint256 maxSlippage_
    )
        internal
        returns (uint256 balanceDifference)
    {
        IERC20 asset = IERC20(assetAdr_);
        uint256 assetsBalanceBefore = asset.balanceOf(address(this));

        /// @dev redeem the vault shares and receive collateral
        uint256 assets = vault_.redeem(amountToRedeem_, address(this), address(this));

        /// @dev collateral balance after
        uint256 assetsBalanceAfter = asset.balanceOf(address(this));
        balanceDifference = assetsBalanceAfter - assetsBalanceBefore;

        if (assets < TOLERANCE_CONSTANT) revert Error.ZERO_AMOUNT();

        /// @dev validate the slippage
        if (
            (balanceDifference < assets - TOLERANCE_CONSTANT)
                || (ENTIRE_SLIPPAGE * assets < ((expectedOutputAmount_ * (ENTIRE_SLIPPAGE - maxSlippage_))))
        ) {
            revert ASSETS_RECEIVED_OUT_OF_SLIPPAGE();
        }
    }

    /// @dev helps parse bytes memory selector
    function _parseSelectorMem(bytes memory data) internal pure returns (bytes4 selector) {
        assembly {
            selector := mload(add(data, 0x20))
        }
    }

    /// @dev helps parse calldata
    function _parseCallData(bytes calldata callData_) internal pure returns (bytes calldata) {
        return callData_[4:];
    }

    function _beforeRebalanceChecks(
        address asset_,
        address user_,
        uint256 rebalanceFromMsgValue_,
        uint256 rebalanceToMsgValue_
    )
        internal
        returns (uint256 balanceBefore, uint256 totalFee)
    {
        if (asset_ == address(0) || user_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        balanceBefore = IERC20(asset_).balanceOf(address(this));

        totalFee = rebalanceFromMsgValue_ + rebalanceToMsgValue_;

        if (msg.value < totalFee) {
            revert INVALID_FEE();
        }
    }

    function _tokenRefunds(address router_, address asset_, address user_, uint256 balanceBefore) internal {
        uint256 balanceDiff = IERC20(asset_).balanceOf(address(this)) - balanceBefore;

        if (balanceDiff > 0) {
            IERC20(asset_).safeTransfer(user_, balanceDiff);
        }

        if (IERC20(asset_).allowance(address(this), router_) > 0) {
            IERC20(asset_).forceApprove(router_, 0);
        }
    }

    /// @dev refunds any unused funds and clears approvals
    function _refundUnusedAndResetApprovals(
        address superPositions_,
        address router_,
        address asset_,
        address user_,
        uint256 balanceBefore,
        uint256 totalFee
    )
        internal
    {
        SuperPositions(superPositions_).setApprovalForAll(router_, false);

        _tokenRefunds(router_, asset_, user_, balanceBefore);

        if (msg.value > totalFee) {
            /// @dev refunds msg.sender if msg.value was more than needed
            (bool success,) = payable(msg.sender).call{ value: msg.value - totalFee }("");

            if (!success) {
                revert Error.FAILED_TO_SEND_NATIVE();
            }
        }
    }
}
