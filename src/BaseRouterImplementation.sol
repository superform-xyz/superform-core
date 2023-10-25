/// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { BaseRouter } from "./BaseRouter.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IBaseStateRegistry } from "./interfaces/IBaseStateRegistry.sol";
import { IBaseRouterImplementation } from "./interfaces/IBaseRouterImplementation.sol";
import { IPayMaster } from "./interfaces/IPayMaster.sol";
import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { IBridgeValidator } from "./interfaces/IBridgeValidator.sol";
import { IStateSyncer } from "./interfaces/IStateSyncer.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { Error } from "./utils/Error.sol";
import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";
import "./crosschain-liquidity/LiquidityHandler.sol";
import "./types/DataTypes.sol";

/// @title BaseRouterImplementation
/// @author Zeropoint Labs
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

    /// @dev getter for PERMIT2 in case it is not supported or set on a given chain
    function _getPermit2() internal view returns (address) {
        address permit2 = superRegistry.PERMIT2();
        if (permit2 == address(0)) {
            revert Error.PERMIT2_NOT_SUPPORTED();
        }
        return permit2;
    }

    /// @dev handles cross-chain multi vault deposit
    function _singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_) internal virtual {
        /// @dev validate superformsData
        if (!_validateSuperformsDepositData(req_.superformsData, req_.dstChainId)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).validateBatchIdsExist(req_.superformsData.superformIds);

        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = CHAIN_ID;
        if (vars.srcChainId == req_.dstChainId) revert Error.INVALID_ACTION();

        vars.currentPayloadId = ++payloadIds;

        ambData = InitMultiVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req_.superformsData.superformIds,
            req_.superformsData.amounts,
            req_.superformsData.maxSlippages,
            req_.superformsData.hasDstSwaps,
            req_.superformsData.liqRequests,
            req_.superformsData.dstRefundAddress,
            req_.superformsData.extraFormData
        );

        address superform;
        uint256 len = req_.superformsData.superformIds.length;

        _multiVaultTokenForward(msg.sender, new address[](0), req_.superformsData.permit2data, ambData, true);

        /// @dev this loop is what allows to deposit to >1 different underlying on destination
        /// @dev if a loop fails in a validation the whole chain should be reverted
        for (uint256 j; j < len;) {
            vars.liqRequest = req_.superformsData.liqRequests[j];

            (superform,,) = req_.superformsData.superformIds[j].getSuperform();

            /// @dev dispatch liquidity data
            _validateAndDispatchTokens(
                ValidateAndDispatchTokensArgs(
                    vars.liqRequest, superform, vars.srcChainId, req_.dstChainId, msg.sender, true
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
                req_.superformsData.superformIds,
                msg.sender,
                req_.ambIds,
                1,
                vars.srcChainId,
                req_.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles cross-chain single vault deposit
    function _singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_) internal virtual {
        ActionLocalVars memory vars;

        vars.srcChainId = CHAIN_ID;

        /// @dev disallow direct chain actions
        if (vars.srcChainId == req_.dstChainId) revert Error.INVALID_ACTION();

        InitSingleVaultData memory ambData;

        /// @dev this step validates and returns ambData from the state request
        (ambData, vars.currentPayloadId) = _buildDepositAmbData(req_.dstChainId, req_.superformData);

        vars.liqRequest = req_.superformData.liqRequest;
        (address superform,,) = req_.superformData.superformId.getSuperform();

        _singleVaultTokenForward(
            msg.sender,
            superRegistry.getBridgeAddress(vars.liqRequest.bridgeId),
            req_.superformData.permit2data,
            ambData
        );

        LiqRequest memory emptyRequest;
        ambData.liqData = emptyRequest;

        /// @dev dispatch liquidity data
        _validateAndDispatchTokens(
            ValidateAndDispatchTokensArgs(
                vars.liqRequest, superform, vars.srcChainId, req_.dstChainId, msg.sender, true
            )
        );

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = req_.superformData.superformId;

        /// @dev dispatch message information, notice multiVaults is set to 0
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.DEPOSIT,
                abi.encode(ambData),
                superformIds,
                msg.sender,
                req_.ambIds,
                0,
                vars.srcChainId,
                req_.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles same-chain single vault deposit
    function _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_) internal virtual {
        /// @dev for direct we don't check if stateSyncer has the correct superform share already created (e.g in
        /// sERC20)
        /// @dev the check is made when directly minting

        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;
        vars.currentPayloadId = ++payloadIds;

        InitSingleVaultData memory vaultData = InitSingleVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req_.superformData.superformId,
            req_.superformData.amount,
            req_.superformData.maxSlippage,
            false,
            req_.superformData.liqRequest,
            req_.superformData.dstRefundAddress,
            req_.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to payment collector
        _directSingleDeposit(msg.sender, req_.superformData.permit2data, vaultData);
        emit Completed(vars.currentPayloadId);
    }

    /// @dev handles same-chain multi vault deposit
    function _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_) internal virtual {
        /// @dev for direct we don't check if stateSyncer has the correct superform share already created (e.g in
        /// sERC20)
        /// @dev the check is made when directly minting

        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;
        vars.currentPayloadId = ++payloadIds;

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req_.superformData.superformIds,
            req_.superformData.amounts,
            req_.superformData.maxSlippages,
            new bool[](req_.superformData.amounts.length),
            req_.superformData.liqRequests,
            req_.superformData.dstRefundAddress,
            req_.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to payment collector
        _directMultiDeposit(msg.sender, req_.superformData.permit2data, vaultData);
        emit Completed(vars.currentPayloadId);
    }

    /// @dev handles cross-chain multi vault withdraw
    function _singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req_) internal virtual {
        /// @dev validate superformsData
        if (!_validateSuperformsWithdrawData(req_.superformsData, req_.dstChainId)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).burnBatch(
            msg.sender, req_.superformsData.superformIds, req_.superformsData.amounts
        );

        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = CHAIN_ID;
        vars.currentPayloadId = ++payloadIds;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req_.superformsData.superformIds,
            req_.superformsData.amounts,
            req_.superformsData.maxSlippages,
            new bool[](req_.superformsData.amounts.length),
            req_.superformsData.liqRequests,
            req_.superformsData.dstRefundAddress,
            req_.superformsData.extraFormData
        );

        /// @dev dispatch message information, notice multiVaults is set to 1
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.WITHDRAW,
                abi.encode(ambData),
                req_.superformsData.superformIds,
                msg.sender,
                req_.ambIds,
                1,
                vars.srcChainId,
                req_.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles cross-chain single vault withdraw
    function _singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_) internal virtual {
        ActionLocalVars memory vars;

        vars.srcChainId = CHAIN_ID;

        if (vars.srcChainId == req_.dstChainId) {
            revert Error.INVALID_CHAIN_IDS();
        }

        if (vars.srcChainId == 0 || req_.dstChainId == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        InitSingleVaultData memory ambData;

        /// @dev this step validates and returns ambData from the state request
        (ambData, vars.currentPayloadId) = _buildWithdrawAmbData(msg.sender, req_.dstChainId, req_.superformData);

        uint256[] memory superformIds = new uint256[](1);
        superformIds[0] = req_.superformData.superformId;

        /// @dev dispatch message information, notice multiVaults is set to 0
        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.WITHDRAW,
                abi.encode(ambData),
                superformIds,
                msg.sender,
                req_.ambIds,
                0,
                vars.srcChainId,
                req_.dstChainId,
                vars.currentPayloadId
            )
        );

        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @dev handles same-chain single vault withdraw
    function _singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req_) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;

        InitSingleVaultData memory ambData;

        (ambData, vars.currentPayloadId) = _buildWithdrawAmbData(msg.sender, vars.srcChainId, req_.superformData);

        /// @dev same chain action
        _directSingleWithdraw(ambData, msg.sender);
        emit Completed(vars.currentPayloadId);
    }

    /// @dev handles same-chain multi vault withdraw
    function _singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req_) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;
        vars.currentPayloadId = ++payloadIds;

        /// @dev SuperPositions are burnt optimistically here
        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).burnBatch(
            msg.sender, req_.superformData.superformIds, req_.superformData.amounts
        );

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            ROUTER_TYPE,
            vars.currentPayloadId,
            req_.superformData.superformIds,
            req_.superformData.amounts,
            req_.superformData.maxSlippages,
            new bool[](req_.superformData.superformIds.length),
            req_.superformData.liqRequests,
            req_.superformData.dstRefundAddress,
            req_.superformData.extraFormData
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
        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).validateSingleIdExists(superformData_.superformId);

        currentPayloadId = ++payloadIds;

        ambData = InitSingleVaultData(
            ROUTER_TYPE,
            currentPayloadId,
            superformData_.superformId,
            superformData_.amount,
            superformData_.maxSlippage,
            superformData_.hasDstSwap,
            superformData_.liqRequest,
            superformData_.dstRefundAddress,
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
            false,
            superformData_.liqRequest,
            superformData_.dstRefundAddress,
            superformData_.extraFormData
        );
    }

    struct ValidateAndDispatchTokensArgs {
        LiqRequest liqRequest;
        address superform;
        uint64 srcChainId;
        uint64 dstChainId;
        address srcSender;
        bool deposit;
    }

    function _validateAndDispatchTokens(ValidateAndDispatchTokensArgs memory args_) internal virtual {
        address bridgeValidator = superRegistry.getBridgeValidator(args_.liqRequest.bridgeId);
        /// @dev validates remaining params of txData
        IBridgeValidator(bridgeValidator).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                args_.liqRequest.txData,
                args_.srcChainId,
                args_.dstChainId,
                args_.liqRequest.liqDstChainId,
                args_.deposit,
                args_.superform,
                args_.srcSender,
                args_.liqRequest.token
            )
        );

        /// @dev dispatches tokens through the selected liquidity bridge to the destination contract
        dispatchTokens(
            superRegistry.getBridgeAddress(args_.liqRequest.bridgeId),
            args_.liqRequest.txData,
            args_.liqRequest.token,
            IBridgeValidator(bridgeValidator).decodeAmountIn(args_.liqRequest.txData, true),
            args_.liqRequest.nativeAmount
        );
    }

    function _dispatchAmbMessage(DispatchAMBMessageVars memory vars_) internal virtual {
        AMBMessage memory ambMessage = AMBMessage(
            DataLib.packTxInfo(
                uint8(vars_.txType),
                uint8(CallbackType.INIT),
                vars_.multiVaults,
                STATE_REGISTRY_TYPE,
                vars_.srcSender,
                vars_.srcChainId
            ),
            vars_.ambData
        );

        (uint256 fees, bytes memory extraData) = IPaymentHelper(superRegistry.getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(vars_.dstChainId, vars_.ambIds, abi.encode(ambMessage));

        /// @dev this call dispatches the message to the AMB bridge through dispatchPayload
        IBaseStateRegistry(superRegistry.getAddress(keccak256("CORE_STATE_REGISTRY"))).dispatchPayload{ value: fees }(
            vars_.srcSender, vars_.ambIds, vars_.dstChainId, abi.encode(ambMessage), extraData
        );

        IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).updateTxHistory(
            vars_.currentPayloadId, ambMessage.txInfo
        );
    }

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice deposits to single vault on the same chain
    /// @dev calls `_directDeposit`
    function _directSingleDeposit(
        address srcSender_,
        bytes memory permit2data_,
        InitSingleVaultData memory vaultData_
    )
        internal
        virtual
    {
        address superform;
        uint256 dstAmount;

        /// @dev decode superforms
        (superform,,) = vaultData_.superformId.getSuperform();

        _singleVaultTokenForward(srcSender_, superform, permit2data_, vaultData_);

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

        if (dstAmount != 0) {
            /// @dev mint super positions at the end of the deposit action
            IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).mintSingle(
                srcSender_, vaultData_.superformId, dstAmount
            );
        }
    }

    struct MultiDepositLocalVars {
        uint256 len;
        address[] superforms;
        uint256[] dstAmounts;
        bool mint;
    }

    /// @notice deposits to multiple vaults on the same chain
    /// @dev loops and call `_directDeposit`
    function _directMultiDeposit(
        address srcSender_,
        bytes memory permit2data_,
        InitMultiVaultData memory vaultData_
    )
        internal
        virtual
    {
        MultiDepositLocalVars memory v;
        v.len = vaultData_.superformIds.length;

        v.superforms = new address[](v.len);
        v.dstAmounts = new uint256[](v.len);

        /// @dev decode superforms
        (v.superforms,,) = DataLib.getSuperforms(vaultData_.superformIds);

        _multiVaultTokenForward(srcSender_, v.superforms, permit2data_, vaultData_, false);

        for (uint256 i; i < v.len;) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            v.dstAmounts[i] = _directDeposit(
                v.superforms[i],
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

            if (v.dstAmounts[i] > 0 && !v.mint) {
                v.mint = true;
            }

            unchecked {
                ++i;
            }
        }

        if (v.mint) {
            /// @dev in direct deposits, SuperPositions are minted right after depositing to vaults
            IStateSyncer(superRegistry.getStateSyncer(ROUTER_TYPE)).mintBatch(
                srcSender_, vaultData_.superformIds, v.dstAmounts
            );
        }
    }

    /// @notice fulfils the final stage of same chain deposit action
    function _directDeposit(
        address superform_,
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
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId_)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }

        if (amount_ == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev deposits collateral to a given vault and mint vault positions directly through the form
        dstAmount = IBaseForm(superform_).directDepositIntoVault{ value: msgValue_ }(
            InitSingleVaultData(
                superformRouterId_,
                payloadId_,
                superformId_,
                amount_,
                maxSlippage_,
                false,
                liqData_,
                address(0),
                /// no need for a refund address
                extraFormData_
            ),
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
            srcSender_,
            vaultData_.dstRefundAddress
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
                srcSender_,
                vaultData_.dstRefundAddress
            );

            unchecked {
                ++i;
            }
        }
    }

    /// @notice fulfils the final stage of same chain withdrawal action
    function _directWithdraw(
        address superform_,
        uint8 superformRouterId_,
        uint256 payloadId_,
        uint256 superformId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_,
        address srcSender_,
        address refundAddress_
    )
        internal
        virtual
    {
        // @dev validates if superformId exists on factory
        if (!ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isSuperform(superformId_)) {
            revert Error.SUPERFORM_ID_NONEXISTENT();
        }

        if (amount_ == 0) {
            revert Error.ZERO_AMOUNT();
        }

        /// @dev in direct withdraws, form is called directly
        IBaseForm(superform_).directWithdrawFromVault(
            InitSingleVaultData(
                superformRouterId_,
                payloadId_,
                superformId_,
                amount_,
                maxSlippage_,
                false,
                liqData_,
                refundAddress_,
                extraFormData_
            ),
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
        /// destination)
        if (dstChainId_ != DataLib.getDestinationChain(superformData_.superformId)) return false;

        /// @dev 10000 = 100% slippage
        if (superformData_.maxSlippage > 10_000) return false;

        /// @dev amount can't be 0
        if (superformData_.amount == 0) return false;

        /// if it reaches this point then is valid
        return true;
    }

    function _validateSuperformsDepositData(
        MultiVaultSFData memory superformsData_,
        uint64 dstChainId_
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

        /// @dev slippage, amount, paused status validation
        for (uint256 i; i < len;) {
            /// @dev 10000 = 100% slippage
            if (superformsData_.maxSlippages[i] > 10_000) return false;
            /// @dev amount can't be 0
            if (superformsData_.amounts[i] == 0) return false;
            (, uint32 formImplementationId_, uint64 sfDstChainId) = superformsData_.superformIds[i].getSuperform();
            if (dstChainId_ != sfDstChainId) return false;

            if (sfDstChainId == 0) {
                revert Error.INVALID_CHAIN_ID();
            }

            if (
                ISuperformFactory(superRegistry.getAddress(keccak256("SUPERFORM_FACTORY"))).isFormImplementationPaused(
                    formImplementationId_
                )
            ) return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    function _validateSuperformsWithdrawData(
        MultiVaultSFData memory superformsData_,
        uint64 dstChainId_
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
            /// @dev amount can't be 0
            if (superformsData_.amounts[i] == 0) return false;
            (,, uint64 sfDstChainId) = superformsData_.superformIds[i].getSuperform();
            if (dstChainId_ != sfDstChainId) return false;
            if (sfDstChainId == 0) {
                revert Error.INVALID_CHAIN_ID();
            }

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
        bytes memory permit2data_,
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
                amount = IBridgeValidator(bridgeValidator).decodeAmountIn(vaultData_.liqData.txData, false);
                /// e.g asset in is USDC (6 decimals), we use this amount to approve the transfer to superform
            }

            if (permit2data_.length != 0) {
                address permit2 = _getPermit2();

                (uint256 nonce, uint256 deadline, bytes memory signature) =
                    abi.decode(permit2data_, (uint256, uint256, bytes));

                /// @dev moves the tokens from the user to the router

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

                /// @dev moves the tokens from the user to the router
                token.safeTransferFrom(srcSender_, address(this), amount);
            }

            /// @dev approves the input amount to the superform
            token.safeIncreaseAllowance(superform_, amount);
        }
    }

    struct MultiTokenForwardLocalVars {
        IERC20 token;
        uint256 len;
        uint256 totalAmount;
        uint256 permit2dataLen;
        address permit2;
        uint256[] approvalAmounts;
    }

    function _multiVaultTokenForward(
        address srcSender_,
        address[] memory targets_,
        bytes memory permit2data_,
        InitMultiVaultData memory vaultData_,
        bool xChain
    )
        internal
        virtual
    {
        address token = vaultData_.liqData[0].token;
        if (token != NATIVE) {
            MultiTokenForwardLocalVars memory v;
            v.token = IERC20(token);
            v.len = vaultData_.liqData.length;

            v.totalAmount;

            v.permit2dataLen = permit2data_.length;
            v.approvalAmounts = new uint256[](v.len);

            for (uint256 i; i < v.len;) {
                if (vaultData_.liqData[i].token != address(v.token)) {
                    revert Error.INVALID_DEPOSIT_TOKEN();
                }

                uint256 len = vaultData_.liqData[i].txData.length;
                if (len == 0 && !xChain) {
                    v.approvalAmounts[i] = vaultData_.amounts[i];
                } else if (len == 0 && xChain) {
                    revert Error.NO_TXDATA_PRESENT();
                } else {
                    address bridgeValidator = superRegistry.getBridgeValidator(vaultData_.liqData[i].bridgeId);
                    v.approvalAmounts[i] =
                        IBridgeValidator(bridgeValidator).decodeAmountIn(vaultData_.liqData[i].txData, false);
                }

                v.totalAmount += v.approvalAmounts[i];
                unchecked {
                    ++i;
                }
            }

            if (v.totalAmount == 0) {
                revert Error.ZERO_AMOUNT();
            }

            if (v.permit2dataLen > 0) {
                (uint256 nonce, uint256 deadline, bytes memory signature) =
                    abi.decode(permit2data_, (uint256, uint256, bytes));

                v.permit2 = _getPermit2();
                /// @dev moves the tokens from the user to the router
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

                /// @dev moves the tokens from the user to the router
                v.token.safeTransferFrom(srcSender_, address(this), v.totalAmount);
            }

            /// @dev approves individual final targets if needed here
            for (uint256 j; j < targets_.length;) {
                /// @dev approves the superform
                v.token.safeIncreaseAllowance(targets_[j], v.approvalAmounts[j]);

                unchecked {
                    ++j;
                }
            }
        }
    }
}
