// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import { DataLib } from "src/libraries/DataLib.sol";
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
import { IBaseStateRegistry } from "src/interfaces/IBaseStateRegistry.sol";
import { IBaseRouter } from "src/interfaces/IBaseRouter.sol";
import { ISuperformRouterLike } from "src/router-plus/ISuperformRouterLike.sol";
import { ISuperformRouterPlus, IERC20 } from "src/interfaces/ISuperformRouterPlus.sol";
import { ISuperformRouterPlusAsync } from "src/interfaces/ISuperformRouterPlusAsync.sol";

/// @title SuperformRouterPlus
/// @dev Performs rebalances and deposits on the Superform platform
/// @author Zeropoint Labs
contract SuperformRouterPlus is ISuperformRouterPlus, BaseSuperformRouterPlus {
    using DataLib for uint256;
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BaseSuperformRouterPlus(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformRouterPlus
    function rebalanceSinglePosition(RebalanceSinglePositionSyncArgs calldata args) external payable override {
        (uint256 balanceBefore, uint256 totalFee) = _beforeRebalanceChecks(
            args.interimAsset, args.receiverAddressSP, args.rebalanceFromMsgValue, args.rebalanceToMsgValue
        );

        /// @dev transfers a single superPosition to this contract and approves router
        _transferSuperPositions(args.receiverAddressSP, args.id, args.sharesToRedeem);
        uint256[] memory sharesToRedeem = new uint256[](1);
        sharesToRedeem[0] = args.sharesToRedeem;
        _rebalancePositionsSync(
            RebalancePositionsSyncArgs(
                Actions.REBALANCE_FROM_SINGLE,
                sharesToRedeem,
                args.previewRedeemAmount,
                args.interimAsset,
                args.slippage,
                args.rebalanceFromMsgValue,
                args.rebalanceToMsgValue,
                args.receiverAddressSP,
                args.smartWallet
            ),
            args.callData,
            args.rebalanceToAmbIds,
            args.rebalanceToDstChainIds,
            args.rebalanceToSfData,
            args.rebalanceToSelector,
            balanceBefore
        );

        _refundUnused(args.interimAsset, args.receiverAddressSP, balanceBefore, totalFee);

        emit RebalanceSyncCompleted(args.receiverAddressSP, args.id, args.sharesToRedeem, args.smartWallet);
    }

    /// @inheritdoc ISuperformRouterPlus
    function rebalanceMultiPositions(RebalanceMultiPositionsSyncArgs calldata args) external payable override {
        (uint256 balanceBefore, uint256 totalFee) = _beforeRebalanceChecks(
            args.interimAsset, args.receiverAddressSP, args.rebalanceFromMsgValue, args.rebalanceToMsgValue
        );

        if (args.ids.length != args.sharesToRedeem.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        /// @dev transfers multiple superPositions to this contract and approves router
        _transferBatchSuperPositions(args.receiverAddressSP, args.ids, args.sharesToRedeem);

        _rebalancePositionsSync(
            RebalancePositionsSyncArgs(
                Actions.REBALANCE_FROM_MULTI,
                args.sharesToRedeem,
                args.previewRedeemAmount,
                args.interimAsset,
                args.slippage,
                args.rebalanceFromMsgValue,
                args.rebalanceToMsgValue,
                args.receiverAddressSP,
                args.smartWallet
            ),
            args.callData,
            args.rebalanceToAmbIds,
            args.rebalanceToDstChainIds,
            args.rebalanceToSfData,
            args.rebalanceToSelector,
            balanceBefore
        );

        _refundUnused(args.interimAsset, args.receiverAddressSP, balanceBefore, totalFee);

        emit RebalanceMultiSyncCompleted(args.receiverAddressSP, args.ids, args.sharesToRedeem, args.smartWallet);
    }

    /// @inheritdoc ISuperformRouterPlus
    function startCrossChainRebalance(InitiateXChainRebalanceArgs calldata args) external payable override {
        if (
            args.rebalanceToAmbIds.length == 0 || args.rebalanceToDstChainIds.length == 0
                || args.rebalanceToSfData.length == 0
        ) {
            revert EMPTY_REBALANCE_CALL_DATA();
        }

        if (args.interimAsset == address(0) || args.receiverAddressSP == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (args.expectedAmountInterimAsset == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev transfers a single superPosition to this contract and approves router
        _transferSuperPositions(args.receiverAddressSP, args.id, args.sharesToRedeem);

        if (!whitelistedSelectors[Actions.REBALANCE_X_CHAIN_FROM_SINGLE][_parseSelectorMem(args.callData)]) {
            revert INVALID_REBALANCE_FROM_SELECTOR();
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
        _callSuperformRouter(args.callData, msg.value);

        if (!whitelistedSelectors[Actions.DEPOSIT][args.rebalanceToSelector]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        ISuperformRouterPlusAsync(ROUTER_PLUS_ASYNC).setXChainRebalanceCallData(
            args.receiverAddressSP,
            ISuperformRouterLike(_getAddress(keccak256("SUPERFORM_ROUTER"))).payloadIds(),
            XChainRebalanceData({
                rebalanceSelector: args.rebalanceToSelector,
                smartWallet: args.smartWallet,
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
            args.id,
            args.sharesToRedeem,
            args.smartWallet,
            args.interimAsset,
            args.finalizeSlippage,
            args.expectedAmountInterimAsset,
            args.rebalanceToSelector
        );
    }

    /// @inheritdoc ISuperformRouterPlus
    function startCrossChainRebalanceMulti(InitiateXChainRebalanceMultiArgs calldata args) external payable override {
        if (args.ids.length != args.sharesToRedeem.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        if (
            args.rebalanceToAmbIds.length == 0 || args.rebalanceToDstChainIds.length == 0
                || args.rebalanceToSfData.length == 0
        ) {
            revert EMPTY_REBALANCE_CALL_DATA();
        }

        if (args.interimAsset == address(0) || args.receiverAddressSP == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (args.expectedAmountInterimAsset == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev transfers multiple superPositions to this contract and approves router
        _transferBatchSuperPositions(args.receiverAddressSP, args.ids, args.sharesToRedeem);

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
                    if (req.superformsData[i].amounts[j] != args.sharesToRedeem[j]) {
                        revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                    }
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

                if (req.superformsData[i].amount != args.sharesToRedeem[i]) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                }

                if (req.superformsData[i].receiverAddress != ROUTER_PLUS_ASYNC) {
                    revert REBALANCE_XCHAIN_INVALID_RECEIVER_ADDRESS();
                }
            }
        }

        /// @dev send SPs to router
        _callSuperformRouter(args.callData, msg.value);

        if (!whitelistedSelectors[Actions.DEPOSIT][args.rebalanceToSelector]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        /// @dev in multiDst multiple payloads ids will be generated on source chain
        ISuperformRouterPlusAsync(ROUTER_PLUS_ASYNC).setXChainRebalanceCallData(
            args.receiverAddressSP,
            ISuperformRouterLike(_getAddress(keccak256("SUPERFORM_ROUTER"))).payloadIds(),
            XChainRebalanceData({
                rebalanceSelector: args.rebalanceToSelector,
                smartWallet: args.smartWallet,
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
            args.ids,
            args.sharesToRedeem,
            args.smartWallet,
            args.interimAsset,
            args.finalizeSlippage,
            args.expectedAmountInterimAsset,
            args.rebalanceToSelector
        );
    }

    /// @inheritdoc ISuperformRouterPlus
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
        payable
        override
    {
        _transferERC20In(IERC20(vault_), receiverAddressSP_, amount_);
        IERC4626 vault = IERC4626(vault_);
        uint256 amountRedeemed = _redeemShare(vault, amount_);

        address assetAdr = vault.asset();
        IERC20 asset = IERC20(assetAdr);

        if (!whitelistedSelectors[Actions.DEPOSIT][depositSelector_]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        /// @dev re-construct calldata
        (bytes memory rebalanceToCallData, bool[] memory sameChain, uint256[][] memory superformIds) =
        _generateRebalanceToCallData(
            depositAmbIds_, depositDstChainIds_, depositSfData_, depositSelector_, smartWallet_
        );

        uint256 balanceBefore = asset.balanceOf(address(this));

        smartWallet_
            ? _depositUsingSmartWallet(
                asset, amountRedeemed, msg.value, receiverAddressSP_, rebalanceToCallData, sameChain, superformIds
            )
            : _deposit(asset, amountRedeemed, msg.value, rebalanceToCallData);

        _tokenRefunds(assetAdr, receiverAddressSP_, balanceBefore);

        emit Deposit4626Completed(receiverAddressSP_, vault_);
    }

    /// @inheritdoc ISuperformRouterPlus
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
        public
        payable
        override
    {
        _transferERC20In(asset_, receiverAddressSP_, amount_);

        if (!whitelistedSelectors[Actions.DEPOSIT][depositSelector_]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }
        /// @dev re-construct calldata
        (bytes memory rebalanceToCallData, bool[] memory sameChain, uint256[][] memory superformIds) =
        _generateRebalanceToCallData(
            depositAmbIds_, depositDstChainIds_, depositSfData_, depositSelector_, smartWallet_
        );

        uint256 balanceBefore = IERC20(asset_).balanceOf(address(this));

        smartWallet_
            ? _depositUsingSmartWallet(
                asset_, amount_, msg.value, receiverAddressSP_, rebalanceToCallData, sameChain, superformIds
            )
            : _deposit(asset_, amount_, msg.value, rebalanceToCallData);

        _tokenRefunds(address(asset_), receiverAddressSP_, balanceBefore);

        emit DepositCompleted(receiverAddressSP_, smartWallet_, false);
    }

    //////////////////////////////////////////////////////////////
    //                   INTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    function _rebalancePositionsSync(
        RebalancePositionsSyncArgs memory args,
        bytes calldata callData,
        bytes calldata rebalanceToAmbIds,
        bytes calldata rebalanceToDstChainIds,
        bytes calldata rebalanceToSfData,
        bytes4 rebalanceSelector,
        uint256 balanceBefore
    )
        internal
    {
        IERC20 asset = IERC20(args.asset);

        /// @dev validate the call data
        if (!whitelistedSelectors[args.action][_parseSelectorMem(callData)]) {
            revert INVALID_REBALANCE_FROM_SELECTOR();
        }

        if (args.action == Actions.REBALANCE_FROM_SINGLE) {
            SingleDirectSingleVaultStateReq memory req =
                abi.decode(_parseCallData(callData), (SingleDirectSingleVaultStateReq));

            if (req.superformData.liqRequest.token != args.asset) {
                revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_TOKEN();
            }
            if (req.superformData.liqRequest.liqDstChainId != CHAIN_ID) {
                revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_CHAIN();
            }
            if (req.superformData.amount != args.sharesToRedeem[0]) {
                revert REBALANCE_SINGLE_POSITIONS_DIFFERENT_AMOUNT();
            }
        } else {
            SingleDirectMultiVaultStateReq memory req =
                abi.decode(_parseCallData(callData), (SingleDirectMultiVaultStateReq));
            uint256 len = req.superformData.liqRequests.length;

            for (uint256 i; i < len; ++i) {
                // Validate that the token and chainId is equal in all indexes
                if (req.superformData.liqRequests[i].token != args.asset) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_TOKEN();
                }
                if (req.superformData.liqRequests[i].liqDstChainId != CHAIN_ID) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_CHAIN();
                }
                if (req.superformData.amounts[i] != args.sharesToRedeem[i]) {
                    revert REBALANCE_MULTI_POSITIONS_DIFFERENT_AMOUNTS();
                }
            }
        }

        /// @dev send SPs to router
        _callSuperformRouter(callData, args.rebalanceFromMsgValue);

        uint256 amountToDeposit = asset.balanceOf(address(this)) - balanceBefore;

        if (amountToDeposit == 0) revert Error.ZERO_AMOUNT();

        if (ENTIRE_SLIPPAGE * amountToDeposit < ((args.previewRedeemAmount * (ENTIRE_SLIPPAGE - args.slippage)))) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }

        /// @dev step 3: rebalance into a new superform with rebalanceCallData
        if (!whitelistedSelectors[Actions.DEPOSIT][rebalanceSelector]) {
            revert INVALID_DEPOSIT_SELECTOR();
        }

        /// @dev re-construct calldata
        (bytes memory rebalanceToCallData, bool[] memory sameChain, uint256[][] memory superformIds) =
        _generateRebalanceToCallData(
            rebalanceToAmbIds, rebalanceToDstChainIds, rebalanceToSfData, rebalanceSelector, args.smartWallet
        );

        args.smartWallet
            ? _depositUsingSmartWallet(
                asset,
                amountToDeposit,
                args.rebalanceToMsgValue,
                args.receiverAddressSP,
                rebalanceToCallData,
                sameChain,
                superformIds
            )
            : _deposit(asset, amountToDeposit, args.rebalanceToMsgValue, rebalanceToCallData);
    }

    function _generateRebalanceToCallData(
        bytes calldata rebalanceToAmbIds,
        bytes calldata rebalanceToDstChainIds,
        bytes calldata rebalanceToSfData,
        bytes4 rebalanceSelector,
        bool smartWallet
    )
        internal
        returns (bytes memory rebalanceToCallData, bool[] memory sameChain, uint256[][] memory superformIds)
    {
        if (rebalanceSelector == IBaseRouter.singleDirectSingleVaultDeposit.selector) {
            SingleVaultSFData memory superformData = abi.decode(rebalanceToSfData, (SingleVaultSFData));

            if (smartWallet) {
                superformIds = new uint256[][](1);
                uint256[] memory superformIdsTemp = new uint256[](1);
                superformIdsTemp[0] = superformData.superformId;
                superformIds[0] = superformIdsTemp;
                sameChain = new bool[](1);
                sameChain[0] = true;
                superformData.receiverAddressSP = address(this);
            }

            rebalanceToCallData =
                abi.encodeWithSelector(rebalanceSelector, SingleDirectSingleVaultStateReq(superformData));
        } else if (rebalanceSelector == IBaseRouter.singleXChainSingleVaultDeposit.selector) {
            SingleVaultSFData memory superformData = abi.decode(rebalanceToSfData, (SingleVaultSFData));

            if (smartWallet) {
                superformData.receiverAddressSP = address(this);
            }
            rebalanceToCallData = abi.encodeWithSelector(
                rebalanceSelector,
                SingleXChainSingleVaultStateReq(
                    abi.decode(rebalanceToAmbIds, (uint8[])),
                    abi.decode(rebalanceToDstChainIds, (uint64)),
                    superformData
                )
            );
        } else if (rebalanceSelector == IBaseRouter.singleDirectMultiVaultDeposit.selector) {
            MultiVaultSFData memory multiSuperformData = abi.decode(rebalanceToSfData, (MultiVaultSFData));

            if (smartWallet) {
                superformIds = new uint256[][](1);
                superformIds[0] = multiSuperformData.superformIds;
                sameChain = new bool[](1);
                sameChain[0] = true;
                multiSuperformData.receiverAddressSP = address(this);
            }
            rebalanceToCallData =
                abi.encodeWithSelector(rebalanceSelector, SingleDirectMultiVaultStateReq(multiSuperformData));
        } else if (rebalanceSelector == IBaseRouter.singleXChainMultiVaultDeposit.selector) {
            MultiVaultSFData memory multiSuperformData = abi.decode(rebalanceToSfData, (MultiVaultSFData));

            if (smartWallet) {
                multiSuperformData.receiverAddressSP = address(this);
            }
            rebalanceToCallData = abi.encodeWithSelector(
                rebalanceSelector,
                SingleXChainMultiVaultStateReq(
                    abi.decode(rebalanceToAmbIds, (uint8[])),
                    abi.decode(rebalanceToDstChainIds, (uint64)),
                    multiSuperformData
                )
            );
        } else if (rebalanceSelector == IBaseRouter.multiDstSingleVaultDeposit.selector) {
            SingleVaultSFData[] memory superformsData = abi.decode(rebalanceToSfData, (SingleVaultSFData[]));

            uint64[] memory dstChains = abi.decode(rebalanceToDstChainIds, (uint64[]));

            if (smartWallet) {
                uint256 len = superformsData.length;

                superformIds = new uint256[][](len);
                sameChain = new bool[](len);

                for (uint256 i; i < len; ++i) {
                    superformIds[i] = new uint256[](1);
                    superformIds[i][0] = superformsData[i].superformId;
                    if (dstChains[i] == CHAIN_ID) {
                        sameChain[i] = true;
                    }
                    superformsData[i].receiverAddressSP = address(this);
                }
            }

            rebalanceToCallData = abi.encodeWithSelector(
                rebalanceSelector,
                MultiDstSingleVaultStateReq(abi.decode(rebalanceToAmbIds, (uint8[][])), dstChains, superformsData)
            );
        } else if (rebalanceSelector == IBaseRouter.multiDstMultiVaultDeposit.selector) {
            MultiVaultSFData[] memory multiSuperformData = abi.decode(rebalanceToSfData, (MultiVaultSFData[]));
            uint64[] memory dstChains = abi.decode(rebalanceToDstChainIds, (uint64[]));

            if (smartWallet) {
                uint256 len = multiSuperformData.length;

                superformIds = new uint256[][](len);
                sameChain = new bool[](len);

                for (uint256 i; i < len; ++i) {
                    multiSuperformData[i].receiverAddressSP = address(this);
                    if (dstChains[i] == CHAIN_ID) {
                        sameChain[i] = true;
                    }
                    uint256 lenSfs = multiSuperformData[i].superformIds.length;
                    uint256[] memory superformIdsTemp = new uint256[](lenSfs);
                    for (uint256 j; j < lenSfs; ++j) {
                        superformIdsTemp[j] = multiSuperformData[i].superformIds[j];
                    }
                    superformIds[i] = superformIdsTemp;
                }
            }

            rebalanceToCallData = abi.encodeWithSelector(
                rebalanceSelector,
                MultiDstMultiVaultStateReq(
                    abi.decode(rebalanceToAmbIds, (uint8[][])),
                    abi.decode(rebalanceToDstChainIds, (uint64[])),
                    multiSuperformData
                )
            );
        } else {
            revert INVALID_REBALANCE_SELECTOR();
        }
    }

    function _transferSuperPositions(address user_, uint256 id_, uint256 amount_) internal {
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));
        SuperPositions(superPositions).safeTransferFrom(user_, address(this), id_, amount_, "");
        SuperPositions(superPositions).setApprovalForOne(_getAddress(keccak256("SUPERFORM_ROUTER")), id_, amount_);
    }

    function _transferBatchSuperPositions(address user_, uint256[] memory ids_, uint256[] memory amounts_) internal {
        address superPositions = _getAddress(keccak256("SUPER_POSITIONS"));

        SuperPositions(superPositions).safeBatchTransferFrom(user_, address(this), ids_, amounts_, "");
        SuperPositions(superPositions).setApprovalForAll(_getAddress(keccak256("SUPERFORM_ROUTER")), true);
    }

    function _transferERC20In(IERC20 erc20_, address user_, uint256 amount_) internal {
        erc20_.transferFrom(user_, address(this), amount_);
    }

    function _redeemShare(IERC4626 vault_, uint256 amountToRedeem_) internal returns (uint256 balanceDifference) {
        IERC20 asset = IERC20(vault_.asset());
        uint256 collateralBalanceBefore = asset.balanceOf(address(this));

        /// @dev redeem the vault shares and receive collateral
        vault_.redeem(amountToRedeem_, address(this), address(this));

        /// @dev collateral balance after
        uint256 collateralBalanceAfter = asset.balanceOf(address(this));

        balanceDifference = collateralBalanceAfter - collateralBalanceBefore;
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

    function _tokenRefunds(address asset_, address user_, uint256 balanceBefore) internal {
        uint256 balanceDiff = IERC20(asset_).balanceOf(address(this)) - balanceBefore;

        if (balanceDiff > 0) {
            IERC20(asset_).transfer(user_, balanceDiff);
        }

        if (IERC20(asset_).allowance(address(this), _getAddress(keccak256("SUPERFORM_ROUTER"))) > 0) {
            IERC20(asset_).forceApprove(_getAddress(keccak256("SUPERFORM_ROUTER")), 0);
        }
    }

    /// @dev refunds any unused refunds
    function _refundUnused(address asset_, address user_, uint256 balanceBefore, uint256 totalFee) internal {
        _tokenRefunds(asset_, user_, balanceBefore);

        if (msg.value > totalFee) {
            /// @dev refunds msg.sender if msg.value was more than needed
            (bool success,) = payable(msg.sender).call{ value: msg.value - totalFee }("");

            if (!success) {
                revert Error.FAILED_TO_SEND_NATIVE();
            }
        }
    }
}
