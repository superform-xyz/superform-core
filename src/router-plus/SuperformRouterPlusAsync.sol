// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { LiqRequest, SingleVaultSFData, MultiVaultSFData } from "src/types/DataTypes.sol";
import { ArrayCastLib } from "src/libraries/ArrayCastLib.sol";
import { Error } from "src/libraries/Error.sol";
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
import { ISuperformRouterPlusAsync } from "src/interfaces/ISuperformRouterPlusAsync.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";

/// @title SuperformRouterPlusAsync
/// @dev Completes the async step of cross chain rebalances and separates the balance from SuperformRouterPlus
/// @author Zeropoint Labs
contract SuperformRouterPlusAsync is ISuperformRouterPlusAsync, BaseSuperformRouterPlus {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(address receiverAddressSP => mapping(uint256 routerPlusPayloadId => XChainRebalanceData data)) public
        xChainRebalanceCallData;

    mapping(uint256 routerPlusPayloadId => Refund) public refunds;
    mapping(uint256 routerPlusPayloadId => bool processed) public processedRebalancePayload;
    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRouterPlus() {
        if (_getAddress(keccak256("SUPERFORM_ROUTER_PLUS")) != msg.sender) {
            revert NOT_ROUTER_PLUS();
        }
        _;
    }

    modifier onlyRouterPlusProcessor() {
        if (!_hasRole(keccak256("ROUTER_PLUS_PROCESSOR_ROLE"), msg.sender)) {
            revert NOT_ROUTER_PLUS_PROCESSOR();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BaseSuperformRouterPlus(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL VIEW FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformRouterPlusAsync
    function decodeXChainRebalanceCallData(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_
    )
        external
        view
        override
        returns (DecodedRouterPlusRebalanceCallData memory D)
    {
        XChainRebalanceData memory data = xChainRebalanceCallData[receiverAddressSP_][routerPlusPayloadId_];
        D.interimAsset = data.interimAsset;
        D.userSlippage = data.slippage;
        D.rebalanceSelector = data.rebalanceSelector;

        if (data.rebalanceSelector == IBaseRouter.singleDirectSingleVaultDeposit.selector) {
            D.superformIds = new uint256[][](1);
            D.amounts = new uint256[][](1);
            D.outputAmounts = new uint256[][](1);

            SingleVaultSFData memory superformData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData));

            D.superformIds[0] = _castUint256ToArray(superformData.superformId);

            D.amounts[0] = _castUint256ToArray(superformData.amount);

            D.outputAmounts[0] = _castUint256ToArray(superformData.outputAmount);

            D.receiverAddress = new address[](1);
            D.receiverAddress[0] = superformData.receiverAddress;
        } else if (data.rebalanceSelector == IBaseRouter.singleXChainSingleVaultDeposit.selector) {
            D.superformIds = new uint256[][](1);
            D.amounts = new uint256[][](1);
            D.outputAmounts = new uint256[][](1);

            SingleVaultSFData memory superformData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData));

            D.superformIds[0] = _castUint256ToArray(superformData.superformId);

            D.amounts[0] = _castUint256ToArray(superformData.amount);

            D.outputAmounts[0] = _castUint256ToArray(superformData.outputAmount);

            D.receiverAddress = new address[](1);
            D.receiverAddress[0] = superformData.receiverAddress;

            D.ambIds = data.rebalanceToAmbIds;

            D.dstChainIds = data.rebalanceToDstChainIds;
        } else if (data.rebalanceSelector == IBaseRouter.singleDirectMultiVaultDeposit.selector) {
            D.superformIds = new uint256[][](1);
            D.amounts = new uint256[][](1);
            D.outputAmounts = new uint256[][](1);

            MultiVaultSFData memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));

            D.superformIds[0] = multiSuperformData.superformIds;
            D.amounts[0] = multiSuperformData.amounts;
            D.outputAmounts[0] = multiSuperformData.outputAmounts;

            D.receiverAddress = new address[](1);
            D.receiverAddress[0] = multiSuperformData.receiverAddress;
        } else if (data.rebalanceSelector == IBaseRouter.singleXChainMultiVaultDeposit.selector) {
            D.superformIds = new uint256[][](1);
            D.amounts = new uint256[][](1);
            D.outputAmounts = new uint256[][](1);

            MultiVaultSFData memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));

            D.superformIds[0] = multiSuperformData.superformIds;
            D.amounts[0] = multiSuperformData.amounts;
            D.outputAmounts[0] = multiSuperformData.outputAmounts;

            D.receiverAddress = new address[](1);
            D.receiverAddress[0] = multiSuperformData.receiverAddress;

            D.ambIds = data.rebalanceToAmbIds;

            D.dstChainIds = data.rebalanceToDstChainIds;
        } else if (data.rebalanceSelector == IBaseRouter.multiDstSingleVaultDeposit.selector) {
            SingleVaultSFData[] memory superformsData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData[]));
            uint256 lenDsts = superformsData.length;

            D.superformIds = new uint256[][](lenDsts);
            D.amounts = new uint256[][](lenDsts);
            D.outputAmounts = new uint256[][](lenDsts);
            D.receiverAddress = new address[](lenDsts);
            D.ambIds = new uint8[][](lenDsts);
            D.dstChainIds = new uint64[](lenDsts);

            D.ambIds = data.rebalanceToAmbIds;
            D.dstChainIds = data.rebalanceToDstChainIds;

            for (uint256 i; i < lenDsts; ++i) {
                uint256[] memory tSuperformIds = new uint256[](1);
                tSuperformIds[0] = superformsData[i].superformId;
                D.superformIds[i] = tSuperformIds;

                uint256[] memory tAmounts = new uint256[](1);
                tAmounts[0] = superformsData[i].amount;
                D.amounts[i] = tAmounts;

                uint256[] memory tOutputAmounts = new uint256[](1);
                tOutputAmounts[0] = superformsData[i].outputAmount;
                D.outputAmounts[i] = tOutputAmounts;

                D.receiverAddress[i] = superformsData[i].receiverAddress;
            }
        } else if (data.rebalanceSelector == IBaseRouter.multiDstMultiVaultDeposit.selector) {
            MultiVaultSFData[] memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData[]));
            uint256 lenDsts = multiSuperformData.length;

            D.superformIds = new uint256[][](lenDsts);
            D.amounts = new uint256[][](lenDsts);
            D.outputAmounts = new uint256[][](lenDsts);
            D.receiverAddress = new address[](lenDsts);
            D.ambIds = new uint8[][](lenDsts);
            D.dstChainIds = new uint64[](lenDsts);

            D.ambIds = data.rebalanceToAmbIds;
            D.dstChainIds = data.rebalanceToDstChainIds;

            for (uint256 i; i < lenDsts; ++i) {
                D.superformIds[i] = multiSuperformData[i].superformIds;
                D.amounts[i] = multiSuperformData[i].amounts;
                D.outputAmounts[i] = multiSuperformData[i].outputAmounts;
                D.receiverAddress[i] = multiSuperformData[i].receiverAddress;
            }
        } else {
            revert INVALID_REBALANCE_SELECTOR();
        }
    }

    //////////////////////////////////////////////////////////////
    //                  EXTERNAL WRITE FUNCTIONS                //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISuperformRouterPlusAsync
    function setXChainRebalanceCallData(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_,
        XChainRebalanceData memory data_
    )
        external
        override
        onlyRouterPlus
    {
        XChainRebalanceData memory currentData = xChainRebalanceCallData[receiverAddressSP_][routerPlusPayloadId_];

        if (currentData.interimAsset != address(0)) revert ALREADY_SET();

        xChainRebalanceCallData[receiverAddressSP_][routerPlusPayloadId_] = data_;
    }

    /// @inheritdoc ISuperformRouterPlusAsync
    function completeCrossChainRebalance(CompleteCrossChainRebalanceArgs memory args_)
        external
        payable
        override
        onlyRouterPlusProcessor
        returns (bool rebalanceSuccessful)
    {
        CompleteCrossChainRebalanceLocalVars memory vars;

        if (processedRebalancePayload[args_.routerPlusPayloadId]) {
            revert REBALANCE_ALREADY_PROCESSED();
        }
        processedRebalancePayload[args_.routerPlusPayloadId] = true;

        XChainRebalanceData memory data = xChainRebalanceCallData[args_.receiverAddressSP][args_.routerPlusPayloadId];
        vars.balanceOfInterim = IERC20(data.interimAsset).balanceOf(address(this));

        if (vars.balanceOfInterim < args_.amountReceivedInterimAsset) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        /// @dev We don't allow negative slippage (and funds are not rescued)
        /// @notice This means that a keeper has to re-submit a completeCrossChainRebalance call
        /// @notice With an amount received lower than expected
        if (args_.amountReceivedInterimAsset > data.expectedAmountInterimAsset) {
            revert Error.NEGATIVE_SLIPPAGE();
        }

        /// @dev any funds left between received and expected remain in this contract
        /// @notice this dust collected cannot be moved outside of this contract but in theory could be used
        /// @notice in future cross chain rebalances (of other users), up to  expectedAmountInterimAsset
        if (
            ENTIRE_SLIPPAGE * args_.amountReceivedInterimAsset
                < ((data.expectedAmountInterimAsset * (ENTIRE_SLIPPAGE - data.slippage)))
        ) {
            refunds[args_.routerPlusPayloadId] =
                Refund(args_.receiverAddressSP, data.interimAsset, args_.amountReceivedInterimAsset, block.timestamp);

            emit RefundInitiated(
                args_.routerPlusPayloadId, args_.receiverAddressSP, data.interimAsset, args_.amountReceivedInterimAsset
            );
            return false;
        }

        vars.interimAsset = IERC20(data.interimAsset);

        /// @dev validate the update of txData by the keeper and re-construct calldata
        /// @notice if there is any failure here because of rebalanceToData misconfiguration a refund should be
        /// initiated
        /// @notice the selectors are validated in SuperformRouterPlus
        if (data.rebalanceSelector == IBaseRouter.singleDirectSingleVaultDeposit.selector) {
            SingleVaultSFData memory superformData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData));

            MultiVaultSFData memory multiSuperformData = _updateSuperformData(
                _castToMultiVaultData(superformData),
                args_.liqRequests[0],
                args_.newAmounts[0],
                args_.newOutputAmounts[0],
                args_.receiverAddressSP,
                data.slippage
            );

            superformData.amount = multiSuperformData.amounts[0];
            superformData.outputAmount = multiSuperformData.outputAmounts[0];
            superformData.liqRequest.txData = multiSuperformData.liqRequests[0].txData;
            superformData.liqRequest.nativeAmount = multiSuperformData.liqRequests[0].nativeAmount;

            vars.rebalanceToCallData = abi.encodeCall(
                IBaseRouter.singleDirectSingleVaultDeposit, (SingleDirectSingleVaultStateReq(superformData))
            );
        } else if (data.rebalanceSelector == IBaseRouter.singleXChainSingleVaultDeposit.selector) {
            SingleVaultSFData memory superformData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData));

            MultiVaultSFData memory multiSuperformData = _updateSuperformData(
                _castToMultiVaultData(superformData),
                args_.liqRequests[0],
                args_.newAmounts[0],
                args_.newOutputAmounts[0],
                args_.receiverAddressSP,
                data.slippage
            );

            superformData.amount = multiSuperformData.amounts[0];
            superformData.outputAmount = multiSuperformData.outputAmounts[0];
            superformData.liqRequest.txData = multiSuperformData.liqRequests[0].txData;
            superformData.liqRequest.nativeAmount = multiSuperformData.liqRequests[0].nativeAmount;

            vars.rebalanceToCallData = abi.encodeCall(
                IBaseRouter.singleXChainSingleVaultDeposit,
                (
                    SingleXChainSingleVaultStateReq(
                        data.rebalanceToAmbIds[0], data.rebalanceToDstChainIds[0], superformData
                    )
                )
            );
        } else if (data.rebalanceSelector == IBaseRouter.singleDirectMultiVaultDeposit.selector) {
            MultiVaultSFData memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));

            multiSuperformData = _updateSuperformData(
                multiSuperformData,
                args_.liqRequests[0],
                args_.newAmounts[0],
                args_.newOutputAmounts[0],
                args_.receiverAddressSP,
                data.slippage
            );

            vars.rebalanceToCallData = abi.encodeCall(
                IBaseRouter.singleDirectMultiVaultDeposit, (SingleDirectMultiVaultStateReq(multiSuperformData))
            );
        } else if (data.rebalanceSelector == IBaseRouter.singleXChainMultiVaultDeposit.selector) {
            MultiVaultSFData memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));

            multiSuperformData = _updateSuperformData(
                multiSuperformData,
                args_.liqRequests[0],
                args_.newAmounts[0],
                args_.newOutputAmounts[0],
                args_.receiverAddressSP,
                data.slippage
            );

            vars.rebalanceToCallData = abi.encodeCall(
                IBaseRouter.singleXChainMultiVaultDeposit,
                (
                    SingleXChainMultiVaultStateReq(
                        data.rebalanceToAmbIds[0], data.rebalanceToDstChainIds[0], multiSuperformData
                    )
                )
            );
        } else if (data.rebalanceSelector == IBaseRouter.multiDstSingleVaultDeposit.selector) {
            SingleVaultSFData[] memory superformsData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData[]));
            uint256 lenDsts = superformsData.length;

            if (args_.liqRequests.length != lenDsts) {
                revert Error.ARRAY_LENGTH_MISMATCH();
            }

            MultiVaultSFData[] memory multiSuperformData = new MultiVaultSFData[](lenDsts);

            for (uint256 i; i < lenDsts; ++i) {
                multiSuperformData[i] = _updateSuperformData(
                    _castToMultiVaultData(superformsData[i]),
                    args_.liqRequests[i],
                    args_.newAmounts[i],
                    args_.newOutputAmounts[i],
                    args_.receiverAddressSP,
                    data.slippage
                );
                superformsData[i].amount = multiSuperformData[i].amounts[0];
                superformsData[i].outputAmount = multiSuperformData[i].outputAmounts[0];
                superformsData[i].liqRequest.txData = multiSuperformData[i].liqRequests[0].txData;
                superformsData[i].liqRequest.nativeAmount = multiSuperformData[i].liqRequests[0].nativeAmount;
            }

            vars.rebalanceToCallData = abi.encodeCall(
                IBaseRouter.multiDstSingleVaultDeposit,
                (MultiDstSingleVaultStateReq(data.rebalanceToAmbIds, data.rebalanceToDstChainIds, superformsData))
            );
        } else if (data.rebalanceSelector == IBaseRouter.multiDstMultiVaultDeposit.selector) {
            MultiVaultSFData[] memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData[]));
            uint256 lenDsts = multiSuperformData.length;
            if (args_.liqRequests.length != lenDsts) {
                revert Error.ARRAY_LENGTH_MISMATCH();
            }

            for (uint256 i; i < lenDsts; ++i) {
                multiSuperformData[i] = _updateSuperformData(
                    multiSuperformData[i],
                    args_.liqRequests[i],
                    args_.newAmounts[i],
                    args_.newOutputAmounts[i],
                    args_.receiverAddressSP,
                    data.slippage
                );
            }

            vars.rebalanceToCallData = abi.encodeCall(
                IBaseRouter.multiDstMultiVaultDeposit,
                (MultiDstMultiVaultStateReq(data.rebalanceToAmbIds, data.rebalanceToDstChainIds, multiSuperformData))
            );
        } else {
            revert INVALID_REBALANCE_SELECTOR();
        }

        _deposit(
            _getAddress(keccak256("SUPERFORM_ROUTER")),
            vars.interimAsset,
            args_.amountReceivedInterimAsset,
            msg.value,
            vars.rebalanceToCallData
        );

        emit XChainRebalanceComplete(args_.receiverAddressSP, args_.routerPlusPayloadId);

        return true;
    }

    /// @inheritdoc ISuperformRouterPlusAsync
    function disputeRefund(uint256 routerPlusPayloadId_) external override {
        Refund storage r = refunds[routerPlusPayloadId_];

        if (!(msg.sender == r.receiver || _hasRole(keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE"), msg.sender))) {
            revert Error.NOT_VALID_DISPUTER();
        }

        if (r.proposedTime == 0 || block.timestamp > r.proposedTime + _getDelay()) revert Error.DISPUTE_TIME_ELAPSED();

        /// @dev just can reset the last proposed time, since amounts should be updated again to
        /// pass the proposedTime zero check in finalize
        r.proposedTime = 0;

        emit RefundDisputed(routerPlusPayloadId_, msg.sender);
    }

    /// @inheritdoc ISuperformRouterPlusAsync
    function proposeRefund(uint256 routerPlusPayloadId_, uint256 refundAmount_) external {
        if (!_hasRole(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), msg.sender)) revert INVALID_PROPOSER();

        Refund storage r = refunds[routerPlusPayloadId_];

        if (r.interimToken == address(0) || r.receiver == address(0)) revert INVALID_REFUND_DATA();
        if (r.proposedTime != 0) revert REFUND_ALREADY_PROPOSED();

        r.proposedTime = block.timestamp;
        r.amount = refundAmount_;

        emit NewRefundAmountProposed(routerPlusPayloadId_, refundAmount_);
    }

    /// @inheritdoc ISuperformRouterPlusAsync
    function finalizeRefund(uint256 routerPlusPayloadId_) external {
        Refund memory r = refunds[routerPlusPayloadId_];

        if (r.proposedTime == 0 || block.timestamp <= r.proposedTime + _getDelay()) revert IN_DISPUTE_PHASE();

        /// @dev deleting to prevent re-entrancy
        delete refunds[routerPlusPayloadId_];

        IERC20(r.interimToken).safeTransfer(r.receiver, r.amount);

        emit RefundCompleted(routerPlusPayloadId_, msg.sender);
    }

    //////////////////////////////////////////////////////////////
    //                   INTERNAL FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev returns the current dispute delay
    function _getDelay() internal view returns (uint256) {
        uint256 delay = superRegistry.delay();
        if (delay == 0) {
            revert Error.DELAY_NOT_SET();
        }
        return delay;
    }

    function _updateSuperformData(
        MultiVaultSFData memory sfData,
        LiqRequest[] memory liqRequests,
        uint256[] memory amounts,
        uint256[] memory outputAmounts,
        address receiverAddressSP,
        uint256 userSlippage
    )
        internal
        pure
        returns (MultiVaultSFData memory)
    {
        uint256 sfDataLen = sfData.liqRequests.length;

        if (sfDataLen != liqRequests.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < sfDataLen; ++i) {
            // Update amounts regardless of txData
            if (ENTIRE_SLIPPAGE * amounts[i] < ((sfData.amounts[i] * (ENTIRE_SLIPPAGE - userSlippage)))) {
                revert COMPLETE_REBALANCE_AMOUNT_OUT_OF_SLIPPAGE(amounts[i], sfData.amounts[i], userSlippage);
            }

            if (ENTIRE_SLIPPAGE * outputAmounts[i] < ((sfData.outputAmounts[i] * (ENTIRE_SLIPPAGE - userSlippage)))) {
                revert COMPLETE_REBALANCE_OUTPUTAMOUNT_OUT_OF_SLIPPAGE(
                    outputAmounts[i], sfData.outputAmounts[i], userSlippage
                );
            }

            sfData.amounts[i] = amounts[i];
            sfData.outputAmounts[i] = outputAmounts[i];

            /// @notice if txData is empty, no update is made
            if (liqRequests[i].txData.length == 0) continue;

            /// @dev handle txData updates and checks
            if (sfData.liqRequests[i].token == address(0)) {
                revert COMPLETE_REBALANCE_INVALID_TX_DATA_UPDATE();
            }

            if (sfData.liqRequests[i].token != liqRequests[i].token) {
                revert COMPLETE_REBALANCE_DIFFERENT_TOKEN();
            }

            if (sfData.liqRequests[i].bridgeId != liqRequests[i].bridgeId) {
                revert COMPLETE_REBALANCE_DIFFERENT_BRIDGE_ID();
            }
            if (sfData.liqRequests[i].liqDstChainId != liqRequests[i].liqDstChainId) {
                revert COMPLETE_REBALANCE_DIFFERENT_CHAIN();
            }
            if (sfData.receiverAddressSP != receiverAddressSP) {
                revert COMPLETE_REBALANCE_DIFFERENT_RECEIVER();
            }

            // Update txData and nativeAmount
            sfData.liqRequests[i].txData = liqRequests[i].txData;
            sfData.liqRequests[i].nativeAmount = liqRequests[i].nativeAmount;
            sfData.liqRequests[i].interimToken = liqRequests[i].interimToken;
        }

        return sfData;
    }

    /// @dev returns if an address has a specific role

    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(id_, addressToCheck_);
    }

    function _castToMultiVaultData(SingleVaultSFData memory data_)
        internal
        pure
        returns (MultiVaultSFData memory castedData_)
    {
        LiqRequest[] memory liqData = new LiqRequest[](1);
        liqData[0] = data_.liqRequest;

        castedData_ = MultiVaultSFData(
            _castUint256ToArray(data_.superformId),
            _castUint256ToArray(data_.amount),
            _castUint256ToArray(data_.outputAmount),
            _castUint256ToArray(data_.maxSlippage),
            liqData,
            data_.permit2data,
            ArrayCastLib.castBoolToArray(data_.hasDstSwap),
            ArrayCastLib.castBoolToArray(data_.retain4626),
            data_.receiverAddress,
            data_.receiverAddressSP,
            data_.extraFormData
        );
    }

    function _castUint256ToArray(uint256 value_) internal pure returns (uint256[] memory casted) {
        casted = new uint256[](1);
        casted[0] = value_;
    }
}
