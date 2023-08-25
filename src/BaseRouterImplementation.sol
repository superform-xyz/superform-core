/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { BaseRouter } from "./BaseRouter.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBaseStateRegistry } from "./interfaces/IBaseStateRegistry.sol";
import { IBaseRouterImplementation } from "./interfaces/IBaseRouterImplementation.sol";
import { IPayMaster } from "./interfaces/IPayMaster.sol";
import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { IFormBeacon } from "./interfaces/IFormBeacon.sol";
import { IBridgeValidator } from "./interfaces/IBridgeValidator.sol";
import { ISuperPositions } from "./interfaces/ISuperPositions.sol";
import { LiquidityHandler } from "./crosschain-liquidity/LiquidityHandler.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { Error } from "./utils/Error.sol";
import "./types/DataTypes.sol";

/// @title BaseRouterImplementation
/// @author Zeropoint Labs.
/// @dev Extends BaseRouter with standard internal execution functions (based on SuperPositions)
abstract contract BaseRouterImplementation is IBaseRouterImplementation, BaseRouter, LiquidityHandler {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev tracks the total payloads
    uint256 public payloadIds;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    /// @param routerType_ the router type
    constructor(address superRegistry_, uint8 routerType_) BaseRouter(superRegistry_, 1) { }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev handles cross-chain multi vault deposit
    function _singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req) internal virtual {
        /// @dev validate superformsData
        if (!_validateSuperformsDepositData(req.superformsData, req.dstChainId)) revert Error.INVALID_SUPERFORMS_DATA();

        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        ambData = InitMultiVaultData(
            vars.currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, req.dstChainId),
            /// @dev no liqDstChainId for deposits
            req.superformsData.superformIds,
            req.superformsData.amounts,
            req.superformsData.maxSlippages,
            new LiqRequest[](0),
            req.superformsData.extraFormData
        );

        address permit2 = superRegistry.PERMIT2();
        address superform;

        /// @dev this loop is what allows to deposit to >1 different underlying on destination
        /// @dev if a loop fails in a validation the whole chain should be reverted
        for (uint256 j = 0; j < req.superformsData.liqRequests.length;) {
            vars.liqRequest = req.superformsData.liqRequests[j];

            (superform,,) = req.superformsData.superformIds[j].getSuperform();

            /// @dev dispatch liquidity data
            _validateAndDispatchTokens(
                vars.liqRequest, permit2, superform, vars.srcChainId, req.dstChainId, req.dstChainId, msg.sender, true
            );
            unchecked {
                ++j;
            }
        }

        /// @dev dispatch message information, notice multiVaults is set to 1
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.DEPOSIT,
                abi.encode(ambData),
                req.superformsData.superformIds,
                msg.sender,
                req.ambIds,
                1,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles cross-chain single vault deposit
    function _singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req) internal virtual {
        ActionLocalVars memory vars;

        vars.srcChainId = superRegistry.chainId();

        /// @dev disallow direct chain actions
        if (vars.srcChainId == req.dstChainId) revert Error.INVALID_CHAIN_IDS();

        InitSingleVaultData memory ambData;

        /// @dev this step validates and returns ambData from the state request
        (ambData, vars.currentPayloadId) = _buildDepositAmbData(req.dstChainId, req.superformData);

        vars.liqRequest = req.superformData.liqRequest;
        (address superform,,) = req.superformData.superformId.getSuperform();

        /// @dev dispatch liquidity data
        _validateAndDispatchTokens(
            vars.liqRequest,
            superRegistry.PERMIT2(),
            superform,
            vars.srcChainId,
            req.dstChainId,
            req.dstChainId,
            msg.sender,
            true
        );

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = req.superformData.superformId;

        /// @dev dispatch message information, notice multiVaults is set to 0
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.DEPOSIT,
                abi.encode(ambData),
                superformIds,
                msg.sender,
                req.ambIds,
                0,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles same-chain single vault deposit
    function _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        InitSingleVaultData memory vaultData = InitSingleVaultData(
            vars.currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, vars.srcChainId),
            /// @dev no liqDstChainId for deposits
            req.superformData.superformId,
            req.superformData.amount,
            req.superformData.maxSlippage,
            req.superformData.liqRequest,
            req.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to payment collector
        _directSingleDeposit(msg.sender, vaultData);
        emit Completed(vars.currentPayloadId);
    }

    /// @dev handles same-chain multi vault deposit
    function _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            vars.currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, vars.srcChainId),
            /// @dev no liqDstChainId for deposits
            req.superformData.superformIds,
            req.superformData.amounts,
            req.superformData.maxSlippages,
            req.superformData.liqRequests,
            req.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to payment collector
        _directMultiDeposit(msg.sender, vaultData);
        emit Completed(vars.currentPayloadId);
    }

    /// @dev handles cross-chain multi vault withdraw
    function _singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req) internal virtual {
        /// @dev validate superformsData
        if (!_validateSuperformsWithdrawData(req.superformsData, req.dstChainId)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        /// @dev FIXME: should stateSyncer have wrappers to all mint and burn functions?
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).burnBatchSP(
            msg.sender, req.superformsData.superformIds, req.superformsData.amounts
        );

        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            vars.currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, req.liqDstChainId),
            req.superformsData.superformIds,
            req.superformsData.amounts,
            req.superformsData.maxSlippages,
            req.superformsData.liqRequests,
            req.superformsData.extraFormData
        );

        /// @dev dispatch message information, notice multiVaults is set to 1
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.WITHDRAW,
                abi.encode(ambData),
                req.superformsData.superformIds,
                msg.sender,
                req.ambIds,
                1,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles cross-chain single vault withdraw
    function _singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req) internal virtual {
        ActionLocalVars memory vars;

        vars.srcChainId = superRegistry.chainId();
        if (vars.srcChainId == req.dstChainId) revert Error.INVALID_CHAIN_IDS();

        InitSingleVaultData memory ambData;

        /// @dev this step validates and returns ambData from the state request
        (ambData, vars.currentPayloadId) =
            _buildWithdrawAmbData(msg.sender, req.dstChainId, req.liqDstChainId, req.superformData);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = req.superformData.superformId;

        /// @dev dispatch message information, notice multiVaults is set to 0
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.WITHDRAW,
                abi.encode(ambData),
                superformIds,
                msg.sender,
                req.ambIds,
                0,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles same-chain single vault withdraw
    function _singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();

        InitSingleVaultData memory ambData;

        (ambData, vars.currentPayloadId) =
            _buildWithdrawAmbData(msg.sender, vars.srcChainId, req.liqDstChainId, req.superformData);

        /// @dev same chain action
        _directSingleWithdraw(ambData, msg.sender);
        emit Completed(vars.currentPayloadId);
    }

    /// @dev handles same-chain multi vault withdraw
    function _singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        /// @dev SuperPositions are burnt optimistically here
        /// @dev FIXME: should stateSyncer have wrappers to all mint and burn functions?
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).burnBatchSP(
            msg.sender, req.superformData.superformIds, req.superformData.amounts
        );

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            vars.currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, req.liqDstChainId),
            req.superformData.superformIds,
            req.superformData.amounts,
            req.superformData.maxSlippages,
            req.superformData.liqRequests,
            req.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to payment collector
        _directMultiWithdraw(vaultData, msg.sender);
        emit Completed(vars.currentPayloadId);
    }

    /*///////////////////////////////////////////////////////////////
                         HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev internal function used for validation and ambData building across different entry points
    function _buildDepositAmbData(
        uint64 dstChainId_,
        SingleVaultSFData memory superformData_
    )
        internal
        virtual
        returns (InitSingleVaultData memory ambData, uint256 currentPayloadId)
    {
        /// @dev validate superformsData
        if (!_validatSuperformData(dstChainId_, superformData_)) revert Error.INVALID_SUPERFORMS_DATA();

        if (
            !IBridgeValidator(superRegistry.getBridgeValidator(superformData_.liqRequest.bridgeId)).validateTxDataAmount(
                superformData_.liqRequest.txData, superformData_.amount
            )
        ) revert Error.INVALID_TXDATA_AMOUNTS();

        currentPayloadId = ++payloadIds;
        LiqRequest memory emptyRequest;

        ambData = InitSingleVaultData(
            currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, dstChainId_),
            /// @dev no liqDstChainId for deposits
            superformData_.superformId,
            superformData_.amount,
            superformData_.maxSlippage,
            emptyRequest,
            superformData_.extraFormData
        );
    }

    function _buildWithdrawAmbData(
        address srcSender_,
        uint64 dstChainId_,
        uint64 liqDstChainId_,
        SingleVaultSFData memory superformData_
    )
        internal
        virtual
        returns (InitSingleVaultData memory ambData, uint256 currentPayloadId)
    {
        /// @dev validate superformsData
        if (!_validatSuperformData(dstChainId_, superformData_)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        /// @dev FIXME: should stateSyncer have wrappers to all mint and burn functions?
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).burnSingleSP(
            srcSender_, superformData_.superformId, superformData_.amount
        );

        currentPayloadId = ++payloadIds;

        ambData = InitSingleVaultData(
            currentPayloadId,
            DataLib.packRouteInfo(ROUTER_TYPE, liqDstChainId_),
            superformData_.superformId,
            superformData_.amount,
            superformData_.maxSlippage,
            superformData_.liqRequest,
            superformData_.extraFormData
        );
    }

    function _validateAndDispatchTokens(
        LiqRequest memory liqRequest_,
        address permit2_,
        address superform_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        uint64 liqDstChainId_,
        address srcSender_,
        bool deposit_
    )
        internal
        virtual
    {
        /// @dev validates remaining params of txData
        IBridgeValidator(superRegistry.getBridgeValidator(liqRequest_.bridgeId)).validateTxData(
            liqRequest_.txData,
            srcChainId_,
            dstChainId_,
            liqDstChainId_,
            deposit_,
            superform_,
            srcSender_,
            liqRequest_.token
        );

        /// @dev dispatches tokens through the selected liquidity bridge to the destnation contract (CoreStateRegistry
        /// or MultiTxProcessor)
        dispatchTokens(
            superRegistry.getBridgeAddress(liqRequest_.bridgeId),
            liqRequest_.txData,
            liqRequest_.token,
            liqRequest_.amount,
            srcSender_,
            liqRequest_.nativeAmount,
            liqRequest_.permit2data,
            permit2_
        );
    }

    function _dispatchAmbMessage(DispatchAMBMessageVars memory vars) internal virtual {
        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(vars.txType),
                uint8(CallbackType.INIT),
                vars.multiVaults,
                STATE_REGISTRY_TYPE,
                vars.srcSender,
                vars.srcChainId
            ),
            vars.ambData
        );

        (uint256 fees, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(vars.dstChainId, vars.ambIds, abi.encode(ambMessage));

        /// @dev this call dispatches the message to the AMB bridge through dispatchPayload
        IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).dispatchPayload{ value: fees }(
            vars.srcSender, vars.ambIds, vars.dstChainId, abi.encode(ambMessage), extraData
        );

        /// @dev FIXME: should call stateSyncer
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).updateTxHistory(
            vars.currentPayloadId, ambMessage.txInfo
        );
    }

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice deposits to single vault on the same chain
    /// @dev calls `_directDeposit`
    function _directSingleDeposit(address srcSender_, InitSingleVaultData memory vaultData_) internal virtual {
        address superform;
        uint256 dstAmount;

        /// @dev decode superforms
        (superform,,) = vaultData_.superformId.getSuperform();

        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            superform,
            vaultData_.payloadId,
            vaultData_.routeInfo,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.liqData,
            vaultData_.extraFormData,
            vaultData_.liqData.nativeAmount,
            srcSender_
        );

        /// @dev mint super positions at the end of the deposit action
        /// @dev FIXME: should stateSyncer have wrappers to all mint and burn functions?
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintSingleSP(
            srcSender_, vaultData_.superformId, dstAmount
        );
    }

    /// @notice deposits to multiple vaults on the same chain
    /// @dev loops and call `_directDeposit`
    function _directMultiDeposit(address srcSender_, InitMultiVaultData memory vaultData_) internal virtual {
        uint256 len = vaultData_.superformIds.length;

        address[] memory superforms = new address[](len);
        uint256[] memory dstAmounts = new uint256[](len);

        /// @dev decode superforms
        (superforms,,) = DataLib.getSuperforms(vaultData_.superformIds);

        for (uint256 i; i < len;) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            dstAmounts[i] = _directDeposit(
                superforms[i],
                vaultData_.payloadId,
                vaultData_.routeInfo,
                vaultData_.superformIds[i],
                vaultData_.amounts[i],
                vaultData_.maxSlippage[i],
                vaultData_.liqData[i],
                vaultData_.extraFormData,
                vaultData_.liqData[i].nativeAmount,
                srcSender_
            );

            unchecked {
                ++i;
            }
        }

        /// @dev in direct deposits, SuperPositions are minted right after depositing to vaults
        /// @dev FIXME: should stateSyncer have wrappers to all mint and burn functions?
        ISuperPositions(superRegistry.getAddress(keccak256("SUPER_POSITIONS"))).mintBatchSP(
            srcSender_, vaultData_.superformIds, dstAmounts
        );
    }

    /// @notice fulfils the final stage of same chain deposit action
    function _directDeposit(
        address superform,
        uint256 payloadId_,
        uint256 routeInfo_,
        uint256 superformId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_,
        uint256 msgValue_,
        address srcSender_
    )
        internal
        virtual
        returns (uint256 dstAmount)
    {
        /// @dev validates if superformId exists on factory
        (,, uint64 chainId) =
            ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getSuperform(superformId_);

        if (chainId != superRegistry.chainId()) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev deposits collateral to a given vault and mint vault positions directly through the form
        dstAmount = IBaseForm(superform).directDepositIntoVault{ value: msgValue_ }(
            InitSingleVaultData(payloadId_, routeInfo_, superformId_, amount_, maxSlippage_, liqData_, extraFormData_),
            srcSender_
        );
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAW HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice withdraws from single vault on the same chain
    /// @dev call `_directWithdraw`
    function _directSingleWithdraw(InitSingleVaultData memory vaultData_, address srcSender_) internal virtual {
        /// @dev decode superforms
        (address superform,,) = vaultData_.superformId.getSuperform();

        _directWithdraw(
            superform,
            vaultData_.payloadId,
            vaultData_.routeInfo,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.liqData,
            vaultData_.extraFormData,
            srcSender_
        );
    }

    /// @notice withdraws from multiple vaults on the same chain
    /// @dev loops and call `_directWithdraw`
    function _directMultiWithdraw(InitMultiVaultData memory vaultData_, address srcSender_) internal virtual {
        /// @dev decode superforms
        (address[] memory superforms,,) = DataLib.getSuperforms(vaultData_.superformIds);

        for (uint256 i; i < superforms.length;) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            _directWithdraw(
                superforms[i],
                vaultData_.payloadId,
                vaultData_.routeInfo,
                vaultData_.superformIds[i],
                vaultData_.amounts[i],
                vaultData_.maxSlippage[i],
                vaultData_.liqData[i],
                vaultData_.extraFormData,
                srcSender_
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice fulfils the final stage of same chain withdrawal action
    function _directWithdraw(
        address superform,
        uint256 txData_,
        uint256 routeInfo_,
        uint256 superformId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_,
        address srcSender_
    )
        internal
        virtual
    {
        /// @dev validates if superformId exists on factory
        (,, uint64 chainId) =
            ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getSuperform(superformId_);

        if (chainId != superRegistry.chainId()) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev in direct withdraws, form is called directly
        IBaseForm(superform).directWithdrawFromVault(
            InitSingleVaultData(txData_, routeInfo_, superformId_, amount_, maxSlippage_, liqData_, extraFormData_),
            srcSender_
        );
    }

    /*///////////////////////////////////////////////////////////////
                            VALIDATION HELPERS
    //////////////////////////////////////////////////////////////*/

    function _validatSuperformData(
        uint64 dstChainId_,
        SingleVaultSFData memory superformData_
    )
        internal
        view
        virtual
        returns (bool)
    {
        /// @dev the dstChainId_ (in the state request) must match the superforms' chainId (superform must exist on
        /// destinatiom)
        if (dstChainId_ != DataLib.getDestinationChain(superformData_.superformId)) return false;

        /// @dev 10000 = 100% slippage
        if (superformData_.maxSlippage > 10_000) return false;

        (, uint32 formBeaconId_,) = superformData_.superformId.getSuperform();

        return !IFormBeacon(
            ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getFormBeacon(formBeaconId_)
        ).paused();
    }

    function _validateSuperformsDepositData(
        MultiVaultSFData memory superformsData_,
        uint64 dstChainId
    )
        internal
        view
        virtual
        returns (bool)
    {
        uint256 len = superformsData_.amounts.length;
        uint256 liqRequestsLen = superformsData_.liqRequests.length;

        /// @dev empty requests are not allowed, as well as requests with length mismatch
        if (len == 0 || liqRequestsLen == 0) return false;
        if (len != liqRequestsLen) return false;

        /// @dev superformIds/amounts/slippages array sizes validation
        if (
            !(
                superformsData_.superformIds.length == superformsData_.amounts.length
                    && superformsData_.superformIds.length == superformsData_.maxSlippages.length
            )
        ) {
            return false;
        }

        /// @dev slippage, amounts and paused status validation
        bool txDataAmountValid;
        for (uint256 i = 0; i < len;) {
            /// @dev 10000 = 100% slippage
            if (superformsData_.maxSlippages[i] > 10_000) return false;
            (, uint32 formBeaconId_, uint64 sfDstChainId) = superformsData_.superformIds[i].getSuperform();
            if (dstChainId != sfDstChainId) return false;

            if (
                IFormBeacon(
                    ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getFormBeacon(
                        formBeaconId_
                    )
                ).paused()
            ) return false;

            /// @dev amounts in liqRequests must match amounts in superformsData_
            txDataAmountValid = IBridgeValidator(
                superRegistry.getBridgeValidator(superformsData_.liqRequests[i].bridgeId)
            ).validateTxDataAmount(superformsData_.liqRequests[i].txData, superformsData_.amounts[i]);

            if (!txDataAmountValid) return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function _validateSuperformsWithdrawData(
        MultiVaultSFData memory superformsData_,
        uint64 dstChainId
    )
        internal
        view
        virtual
        returns (bool)
    {
        uint256 len = superformsData_.amounts.length;
        uint256 liqRequestsLen = superformsData_.liqRequests.length;

        /// @dev empty requests are not allowed, as well as requests with length mismatch
        if (len == 0 || liqRequestsLen == 0) return false;

        if (liqRequestsLen != len) {
            return false;
        }

        /// @dev superformIds/amounts/slippages array sizes validation
        if (
            !(
                superformsData_.superformIds.length == superformsData_.amounts.length
                    && superformsData_.superformIds.length == superformsData_.maxSlippages.length
            )
        ) {
            return false;
        }

        /// @dev slippage and paused status validation
        for (uint256 i; i < len;) {
            /// @dev 10000 = 100% slippage
            if (superformsData_.maxSlippages[i] > 10_000) return false;
            (, uint32 formBeaconId_, uint64 sfDstChainId) = superformsData_.superformIds[i].getSuperform();
            if (dstChainId != sfDstChainId) return false;

            if (
                IFormBeacon(
                    ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getFormBeacon(
                        formBeaconId_
                    )
                ).paused()
            ) return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                        FEE FORWARDING HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev forwards the residual payment to payment collector
    function _forwardPayment(uint256 _balanceBefore) internal virtual {
        /// @dev deducts what's already available sends what's left in msg.value to payment collector
        uint256 residualPayment = address(this).balance - _balanceBefore;

        if (residualPayment > 0) {
            IPayMaster(superRegistry.getAddress(keccak256("PAYMASTER"))).makePayment{ value: residualPayment }(
                msg.sender
            );
        }
    }
}
