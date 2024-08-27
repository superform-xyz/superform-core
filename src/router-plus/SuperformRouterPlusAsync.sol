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
/// @dev Completes the async step of cross chain rebalances
/// @author Zeropoint Labs
contract SuperformRouterPlusAsync is ISuperformRouterPlusAsync, BaseSuperformRouterPlus {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(address receiverAddressSP => mapping(uint256 routerPlusPayloadId => XChainRebalanceData data)) public
        xChainRebalanceCallData;
    mapping(uint256 routerPlusPayloadId => Refund) public refunds;

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
        if (!_hasRole(keccak256("ROUTER_PLUS_PROCESSOR"), msg.sender)) {
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
    function getXChainRebalanceCallData(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_
    )
        external
        view
        override
        returns (XChainRebalanceData memory)
    {
        return xChainRebalanceCallData[receiverAddressSP_][routerPlusPayloadId_];
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
        xChainRebalanceCallData[receiverAddressSP_][routerPlusPayloadId_] = data_;
    }

    /// @inheritdoc ISuperformRouterPlusAsync
    function completeCrossChainRebalance(
        address receiverAddressSP_,
        uint256 routerPlusPayloadId_,
        uint256 amountReceivedInterimAsset_,
        LiqRequest[][] memory liqRequests_
    )
        external
        payable
        override
        onlyRouterPlusProcessor
        returns (bool rebalanceSuccessful)
    {
        XChainRebalanceData memory data = xChainRebalanceCallData[receiverAddressSP_][routerPlusPayloadId_];
        uint256 balanceOfInterim = IERC20(data.interimAsset).balanceOf(address(this));

        if (balanceOfInterim < amountReceivedInterimAsset_) {
            revert Error.INSUFFICIENT_BALANCE();
        }

        if (
            ENTIRE_SLIPPAGE * amountReceivedInterimAsset_
                < ((data.expectedAmountInterimAsset * (ENTIRE_SLIPPAGE - data.slippage)))
        ) {
            refunds[routerPlusPayloadId_] =
                Refund(receiverAddressSP_, data.interimAsset, amountReceivedInterimAsset_, block.timestamp);

            emit RefundInitiated(
                routerPlusPayloadId_, receiverAddressSP_, data.interimAsset, amountReceivedInterimAsset_
            );
            return false;
        }

        /// TODO verify if this is desired or we just deposit amountReceivedInterimAsset_
        /// The idea is that balance here can be greater or equal to amountReceivedInterimAsset_
        /// If the balance is greater or equal than expected amount then the difference is sent to paymaster
        /// If it is lower then the full balance is deposited (which can be equal to amountReceivedInterimAsset_ or not)
        /// This means that at most, expectedAmountInterimAsset can be sent as external token and the rebalanceToSfData
        /// information in amounts/outputAmounts should have that reflected from the get go in the first step
        uint256 amountToDeposit;
        IERC20 interimAsset = IERC20(data.interimAsset);

        if (balanceOfInterim >= data.expectedAmountInterimAsset) {
            amountToDeposit = data.expectedAmountInterimAsset;
            /// @dev transfer the remaining balance to the paymaster
            interimAsset.safeTransfer(_getAddress(keccak256("PAYMASTER")), balanceOfInterim - amountToDeposit);
        } else {
            amountToDeposit = balanceOfInterim;
        }

        /// @dev validate the update of txData by the keeper and re-construct calldata
        bytes memory rebalanceToCallData;
        bool[] memory sameChain;
        uint256[][] memory superformIds;

        if (data.rebalanceSelector == IBaseRouter.singleDirectSingleVaultDeposit.selector) {
            SingleVaultSFData memory superformData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData));

            MultiVaultSFData memory multiSuperformData =
                _updateSuperformData(_castToMultiVaultData(superformData), liqRequests_[0]);

            superformData.liqRequest.txData = multiSuperformData.liqRequests[0].txData;
            superformData.liqRequest.nativeAmount = multiSuperformData.liqRequests[0].nativeAmount;

            rebalanceToCallData =
                abi.encodeWithSelector(data.rebalanceSelector, SingleDirectSingleVaultStateReq(superformData));
        } else if (data.rebalanceSelector == IBaseRouter.singleXChainSingleVaultDeposit.selector) {
            SingleVaultSFData memory superformData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData));

            MultiVaultSFData memory multiSuperformData =
                _updateSuperformData(_castToMultiVaultData(superformData), liqRequests_[0]);

            superformData.liqRequest.txData = multiSuperformData.liqRequests[0].txData;
            superformData.liqRequest.nativeAmount = multiSuperformData.liqRequests[0].nativeAmount;

            rebalanceToCallData = abi.encodeWithSelector(
                data.rebalanceSelector,
                SingleXChainSingleVaultStateReq(
                    abi.decode(data.rebalanceToAmbIds, (uint8[])),
                    abi.decode(data.rebalanceToDstChainIds, (uint64)),
                    superformData
                )
            );
        } else if (data.rebalanceSelector == IBaseRouter.singleDirectMultiVaultDeposit.selector) {
            MultiVaultSFData memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));

            multiSuperformData = _updateSuperformData(multiSuperformData, liqRequests_[0]);

            rebalanceToCallData =
                abi.encodeWithSelector(data.rebalanceSelector, SingleDirectMultiVaultStateReq(multiSuperformData));
        } else if (data.rebalanceSelector == IBaseRouter.singleXChainMultiVaultDeposit.selector) {
            MultiVaultSFData memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData));

            multiSuperformData = _updateSuperformData(multiSuperformData, liqRequests_[0]);

            rebalanceToCallData = abi.encodeWithSelector(
                data.rebalanceSelector,
                SingleXChainMultiVaultStateReq(
                    abi.decode(data.rebalanceToAmbIds, (uint8[])),
                    abi.decode(data.rebalanceToDstChainIds, (uint64)),
                    multiSuperformData
                )
            );
        } else if (data.rebalanceSelector == IBaseRouter.multiDstSingleVaultDeposit.selector) {
            SingleVaultSFData[] memory superformsData = abi.decode(data.rebalanceToSfData, (SingleVaultSFData[]));
            uint256 len = superformsData.length;

            if (liqRequests_.length != len) {
                revert Error.ARRAY_LENGTH_MISMATCH();
            }

            MultiVaultSFData[] memory multiSuperformData = new MultiVaultSFData[](len);

            for (uint256 i; i < len; ++i) {
                multiSuperformData[i] = _updateSuperformData(_castToMultiVaultData(superformsData[i]), liqRequests_[i]);
                superformsData[i].liqRequest.txData = multiSuperformData[i].liqRequests[0].txData;
                superformsData[i].liqRequest.nativeAmount = multiSuperformData[i].liqRequests[0].nativeAmount;
            }

            rebalanceToCallData = abi.encodeWithSelector(
                data.rebalanceSelector,
                MultiDstSingleVaultStateReq(
                    abi.decode(data.rebalanceToAmbIds, (uint8[][])),
                    abi.decode(data.rebalanceToDstChainIds, (uint64[])),
                    superformsData
                )
            );
        } else if (data.rebalanceSelector == IBaseRouter.multiDstMultiVaultDeposit.selector) {
            MultiVaultSFData[] memory multiSuperformData = abi.decode(data.rebalanceToSfData, (MultiVaultSFData[]));
            uint256 len = multiSuperformData.length;
            if (liqRequests_.length != len) {
                revert Error.ARRAY_LENGTH_MISMATCH();
            }

            for (uint256 i; i < len; ++i) {
                multiSuperformData[i] = _updateSuperformData(multiSuperformData[i], liqRequests_[i]);
            }

            rebalanceToCallData = abi.encodeWithSelector(
                data.rebalanceSelector,
                MultiDstMultiVaultStateReq(
                    abi.decode(data.rebalanceToAmbIds, (uint8[][])),
                    abi.decode(data.rebalanceToDstChainIds, (uint64[])),
                    multiSuperformData
                )
            );
        } else {
            revert INVALID_REBALANCE_SELECTOR();
        }

        _deposit(interimAsset, amountToDeposit, msg.value, rebalanceToCallData);

        emit XChainRebalanceComplete(receiverAddressSP_, routerPlusPayloadId_);

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

    function _castToMultiVaultData(SingleVaultSFData memory data_)
        internal
        pure
        returns (MultiVaultSFData memory castedData_)
    {
        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = data_.superformId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = data_.amount;

        uint256[] memory outputAmounts = new uint256[](1);
        outputAmounts[0] = data_.outputAmount;

        uint256[] memory maxSlippage = new uint256[](1);
        maxSlippage[0] = data_.maxSlippage;

        LiqRequest[] memory liqData = new LiqRequest[](1);
        liqData[0] = data_.liqRequest;

        castedData_ = MultiVaultSFData(
            superformIds,
            amounts,
            outputAmounts,
            maxSlippage,
            liqData,
            data_.permit2data,
            ArrayCastLib.castBoolToArray(data_.hasDstSwap),
            ArrayCastLib.castBoolToArray(data_.retain4626),
            data_.receiverAddress,
            data_.receiverAddressSP,
            data_.extraFormData
        );
    }

    function _updateSuperformData(
        MultiVaultSFData memory sfData,
        LiqRequest[] memory liqRequest
    )
        internal
        returns (MultiVaultSFData memory)
    {
        uint256 sfDataLen = sfData.liqRequests.length;

        if (sfDataLen != liqRequest.length) {
            revert Error.ARRAY_LENGTH_MISMATCH();
        }

        for (uint256 i; i < sfDataLen; ++i) {
            if (
                (sfData.liqRequests[i].token == address(0) && liqRequest[i].txData.length != 0)
                    || (sfData.liqRequests[i].token != address(0) && liqRequest[i].txData.length == 0)
            ) {
                revert COMPLETE_REBALANCE_INVALID_TX_DATA_UPDATE();
            } else if (sfData.liqRequests[i].token != address(0) && liqRequest[i].txData.length != 0) {
                if (sfData.liqRequests[i].token != liqRequest[i].token) {
                    revert COMPLETE_REBALANCE_DIFFERENT_TOKEN();
                }
                if (sfData.liqRequests[i].interimToken != liqRequest[i].interimToken) {
                    revert COMPLETE_REBALANCE_DIFFERENT_TOKEN();
                }
                if (sfData.liqRequests[i].bridgeId != liqRequest[i].bridgeId) {
                    revert COMPLETE_REBALANCE_DIFFERENT_BRIDGE_ID();
                }
                if (sfData.liqRequests[i].liqDstChainId != liqRequest[i].liqDstChainId) {
                    revert COMPLETE_REBALANCE_DIFFERENT_CHAIN();
                }

                // update the txData and native amount
                sfData.liqRequests[i].txData = liqRequest[i].txData;
                sfData.liqRequests[i].nativeAmount = liqRequest[i].nativeAmount;
            }
        }
        /// if token and txData are 0 no update is made (same chain actions without swaps)

        return sfData;
    }

    /// @dev returns if an address has a specific role
    function _hasRole(bytes32 id_, address addressToCheck_) internal view returns (bool) {
        return ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(id_, addressToCheck_);
    }
}
