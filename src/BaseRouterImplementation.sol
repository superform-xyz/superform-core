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
import { IStateSyncer } from "./interfaces/IStateSyncer.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { Error } from "./utils/Error.sol";
import "./crosschain-liquidity/LiquidityHandler.sol";
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
    /// @param stateRegistryType_ the state registry type
    /// @param routerType_ the router type
    constructor(
        address superRegistry_,
        uint8 stateRegistryType_,
        uint8 routerType_
    )
        BaseRouter(superRegistry_, stateRegistryType_, routerType_)
    { }

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
            ROUTER_TYPE,
            vars.currentPayloadId,
            req.superformsData.superformIds,
            req.superformsData.amounts,
            req.superformsData.maxSlippages,
            req.superformsData.liqRequests,
            req.superformsData.permit2data,
            req.superformsData.extraFormData
        );

        address permit2 = superRegistry.PERMIT2();
        address superform;
        uint256 len = req.superformsData.superformIds.length;

        address[] memory targets = new address[](len);

        for (uint256 i; i < len;) {
            targets[i] = superRegistry.getBridgeAddress(req.superformsData.liqRequests[i].bridgeId);

            unchecked {
                ++i;
            }
        }

        _multiVaultTokenForward(msg.sender, targets, ambData);

        /// @dev this loop is what allows to deposit to >1 different underlying on destination
        /// @dev if a loop fails in a validation the whole chain should be reverted
        for (uint256 j; j < len;) {
            vars.liqRequest = req.superformsData.liqRequests[j];

            (superform,,) = req.superformsData.superformIds[j].getSuperform();

            /// @dev dispatch liquidity data
            _validateAndDispatchTokens(
                ValidateAndDispatchTokensArgs(
                    vars.liqRequest, permit2, superform, vars.srcChainId, req.dstChainId, msg.sender, true
                )
            );
            unchecked {
                ++j;
            }
        }

        ambData.liqData = new LiqRequest[](len);

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

        _singleVaultTokenForward(msg.sender, superRegistry.getBridgeAddress(vars.liqRequest.bridgeId), ambData);

        LiqRequest memory emptyRequest;
        ambData.liqData = emptyRequest;

        /// @dev dispatch liquidity data
        _validateAndDispatchTokens(
            ValidateAndDispatchTokensArgs(
                vars.liqRequest, superRegistry.PERMIT2(), superform, vars.srcChainId, req.dstChainId, msg.sender, true
            )
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
            ROUTER_TYPE,
            vars.currentPayloadId,
            req.superformData.superformId,
            req.superformData.amount,
            req.superformData.maxSlippage,
            req.superformData.liqRequest,
            req.superformData.permit2data,
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
            ROUTER_TYPE,
            vars.currentPayloadId,
            req.superformData.superformIds,
            req.superformData.amounts,
            req.superformData.maxSlippages,
            req.superformData.liqRequests,
            req.superformData.permit2data,
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

        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).burnBatch(
            msg.sender, req.superformsData.superformIds, req.superformsData.amounts
        );

        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req.superformsData.superformIds,
            req.superformsData.amounts,
            req.superformsData.maxSlippages,
            req.superformsData.liqRequests,
            req.superformsData.permit2data,
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
        (ambData, vars.currentPayloadId) = _buildWithdrawAmbData(msg.sender, req.dstChainId, req.superformData);

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

        (ambData, vars.currentPayloadId) = _buildWithdrawAmbData(msg.sender, vars.srcChainId, req.superformData);

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
        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).burnBatch(
            msg.sender, req.superformData.superformIds, req.superformData.amounts
        );

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req.superformData.superformIds,
            req.superformData.amounts,
            req.superformData.maxSlippages,
            req.superformData.liqRequests,
            req.superformData.permit2data,
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
        if (!_validateSuperformData(dstChainId_, superformData_)) revert Error.INVALID_SUPERFORMS_DATA();

        if (
            !IBridgeValidator(superRegistry.getBridgeValidator(superformData_.liqRequest.bridgeId)).validateTxDataAmount(
                superformData_.liqRequest.txData, superformData_.amount
            )
        ) revert Error.INVALID_TXDATA_AMOUNTS();

        currentPayloadId = ++payloadIds;

        ambData = InitSingleVaultData(
            ROUTER_TYPE,
            currentPayloadId,
            superformData_.superformId,
            superformData_.amount,
            superformData_.maxSlippage,
            superformData_.liqRequest,
            superformData_.permit2data,
            superformData_.extraFormData
        );
    }

    function _buildWithdrawAmbData(
        address srcSender_,
        uint64 dstChainId_,
        SingleVaultSFData memory superformData_
    )
        internal
        virtual
        returns (InitSingleVaultData memory ambData, uint256 currentPayloadId)
    {
        /// @dev validate superformsData
        if (!_validateSuperformData(dstChainId_, superformData_)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).burnSingle(
            srcSender_, superformData_.superformId, superformData_.amount
        );

        currentPayloadId = ++payloadIds;

        ambData = InitSingleVaultData(
            ROUTER_TYPE,
            currentPayloadId,
            superformData_.superformId,
            superformData_.amount,
            superformData_.maxSlippage,
            superformData_.liqRequest,
            superformData_.permit2data,
            superformData_.extraFormData
        );
    }

    struct ValidateAndDispatchTokensArgs {
        LiqRequest liqRequest;
        address permit2;
        address superform;
        uint64 srcChainId;
        uint64 dstChainId;
        address srcSender;
        bool deposit;
    }

    function _validateAndDispatchTokens(ValidateAndDispatchTokensArgs memory args) internal virtual {
        address bridgeValidator = superRegistry.getBridgeValidator(args.liqRequest.bridgeId);
        /// @dev validates remaining params of txData
        IBridgeValidator(bridgeValidator).validateTxData(
            args.liqRequest.txData,
            args.srcChainId,
            args.dstChainId,
            args.liqRequest.liqDstChainId,
            args.deposit,
            args.superform,
            args.srcSender,
            args.liqRequest.token
        );

        /// @dev dispatches tokens through the selected liquidity bridge to the destnation contract
        dispatchTokens(
            superRegistry.getBridgeAddress(args.liqRequest.bridgeId),
            args.liqRequest.txData,
            args.liqRequest.token,
            IBridgeValidator(bridgeValidator).decodeAmountIn(args.liqRequest.txData),
            args.srcSender,
            args.liqRequest.nativeAmount
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

        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).updateTxHistory(
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

        _singleVaultTokenForward(srcSender_, superform, vaultData_);

        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            superform,
            vaultData_.superformRouterId,
            vaultData_.payloadId,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.liqData,
            vaultData_.extraFormData,
            vaultData_.liqData.nativeAmount,
            srcSender_
        );

        /// @dev mint super positions at the end of the deposit action
        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).mintSingle(
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

        _multiVaultTokenForward(srcSender_, superforms, vaultData_);

        for (uint256 i; i < len;) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            dstAmounts[i] = _directDeposit(
                superforms[i],
                vaultData_.superformRouterId,
                vaultData_.payloadId,
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
        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).mintBatch(
            srcSender_, vaultData_.superformIds, dstAmounts
        );
    }

    /// @notice fulfils the final stage of same chain deposit action
    function _directDeposit(
        address superform,
        uint8 superformRouterId_,
        uint256 payloadId_,
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

        if (amount_ == 0) {
            revert Error.ZERO_AMOUNT();
        }

        if (chainId != superRegistry.chainId()) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev deposits collateral to a given vault and mint vault positions directly through the form
        dstAmount = IBaseForm(superform).directDepositIntoVault{ value: msgValue_ }(
            InitSingleVaultData(
                superformRouterId_, payloadId_, superformId_, amount_, maxSlippage_, liqData_, "", extraFormData_
            ),
            /// FIXME: come later
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
            vaultData_.superformRouterId,
            vaultData_.payloadId,
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
        uint256 len = superforms.length;

        for (uint256 i; i < len;) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            _directWithdraw(
                superforms[i],
                vaultData_.superformRouterId,
                vaultData_.payloadId,
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
        uint8 superformRouterId_,
        uint256 payloadId_,
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
            InitSingleVaultData(
                superformRouterId_, payloadId_, superformId_, amount_, maxSlippage_, liqData_, "", extraFormData_
            ),
            /// FIXME: come later
            srcSender_
        );
    }

    /*///////////////////////////////////////////////////////////////
                            VALIDATION HELPERS
    //////////////////////////////////////////////////////////////*/

    function _validateSuperformData(
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

        return IFormBeacon(
            ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).getFormBeacon(formBeaconId_)
        ).paused() == 1;
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
                ).paused() == 2
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
                ).paused() == 2
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

    /*///////////////////////////////////////////////////////////////
                    SAME CHAIN TOKEN SETTLEMENT HELPERS
    //////////////////////////////////////////////////////////////*/
    function _singleVaultTokenForward(
        address srcSender_,
        address superform_,
        InitSingleVaultData memory vaultData_
    )
        internal
        virtual
    {
        if (vaultData_.liqData.token != NATIVE) {
            IERC20 token = IERC20(vaultData_.liqData.token);
            uint256 len = vaultData_.liqData.txData.length;
            uint256 amount;

            if (len == 0) {
                amount = vaultData_.amount;
            } else {
                address bridgeValidator = superRegistry.getBridgeValidator(vaultData_.liqData.bridgeId);
                amount = IBridgeValidator(bridgeValidator).decodeAmountIn(vaultData_.liqData.txData);
            }

            if (vaultData_.permit2data.length != 0) {
                address permit2 = superRegistry.PERMIT2();

                (uint256 nonce, uint256 deadline, bytes memory signature) =
                    abi.decode(vaultData_.permit2data, (uint256, uint256, bytes));

                IPermit2(permit2).permitTransferFrom(
                    // The permit message.
                    IPermit2.PermitTransferFrom({
                        permitted: IPermit2.TokenPermissions({ token: token, amount: amount }),
                        nonce: nonce,
                        deadline: deadline
                    }),
                    // The transfer recipient and amount.
                    IPermit2.SignatureTransferDetails({ to: address(this), requestedAmount: amount }),
                    // The owner of the tokens, which must also be
                    // the signer of the message, otherwise this call
                    // will fail.
                    srcSender_,
                    // The packed signature that was the result of signing
                    // the EIP712 hash of `permit`.
                    signature
                );
            } else {
                if (token.allowance(srcSender_, address(this)) < amount) {
                    revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
                }

                /// @dev moves the tokens from the user and approves the form
                token.safeTransferFrom(srcSender_, address(this), amount);
            }

            /// @dev approves the superform
            token.approve(superform_, amount);
        }
    }

    struct MultiTokenForwardLocalVars {
        IERC20 token;
        uint256 totalAmount;
        uint256 permit2dataLen;
        address permit2;
    }

    function _multiVaultTokenForward(
        address srcSender_,
        address[] memory superforms_,
        InitMultiVaultData memory vaultData_
    )
        internal
        virtual
    {
        if (vaultData_.liqData[0].token != NATIVE) {
            MultiTokenForwardLocalVars memory v;
            v.token = IERC20(vaultData_.liqData[0].token);

            v.totalAmount;
            v.permit2 = superRegistry.PERMIT2();
            v.permit2dataLen = vaultData_.permit2data.length;

            for (uint256 i; i < vaultData_.liqData.length;) {
                /// FIXME: add revert message
                if (vaultData_.liqData[i].token != address(v.token)) {
                    revert();
                }

                uint256 len = vaultData_.liqData[i].txData.length;

                if (len == 0) {
                    v.totalAmount += vaultData_.amounts[i];
                } else {
                    address bridgeValidator = superRegistry.getBridgeValidator(vaultData_.liqData[i].bridgeId);
                    v.totalAmount += IBridgeValidator(bridgeValidator).decodeAmountIn(vaultData_.liqData[i].txData);
                }

                unchecked {
                    ++i;
                }
            }

            if (v.totalAmount > 0) {
                if (v.permit2dataLen > 0) {
                    (uint256 nonce, uint256 deadline, bytes memory signature) =
                        abi.decode(vaultData_.permit2data, (uint256, uint256, bytes));

                    IPermit2(v.permit2).permitTransferFrom(
                        // The permit message.
                        IPermit2.PermitTransferFrom({
                            permitted: IPermit2.TokenPermissions({ token: v.token, amount: v.totalAmount }),
                            nonce: nonce,
                            deadline: deadline
                        }),
                        // The transfer recipient and amount.
                        IPermit2.SignatureTransferDetails({ to: address(this), requestedAmount: v.totalAmount }),
                        // The owner of the tokens, which must also be
                        // the signer of the message, otherwise this call
                        // will fail.
                        srcSender_,
                        // The packed signature that was the result of signing
                        // the EIP712 hash of `permit`.
                        signature
                    );
                } else {
                    if (v.token.allowance(srcSender_, address(this)) < v.totalAmount) {
                        revert Error.DIRECT_DEPOSIT_INSUFFICIENT_ALLOWANCE();
                    }

                    /// @dev moves the tokens from the user and approves the form
                    v.token.safeTransferFrom(srcSender_, address(this), v.totalAmount);
                }
            }

            /// FIXME: this is hacky
            for (uint256 j; j < superforms_.length;) {
                /// @dev approves the superform
                v.token.approve(superforms_[j], v.totalAmount);

                unchecked {
                    ++j;
                }
            }
        }
    }
}
