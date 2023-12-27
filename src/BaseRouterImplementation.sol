// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BaseRouter } from "./BaseRouter.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC1155Receiver } from "openzeppelin-contracts/contracts/token/ERC1155/IERC1155Receiver.sol";
import { IERC165 } from "openzeppelin-contracts/contracts/utils/introspection/IERC165.sol";
import { IERC1155Errors } from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";
import { IBaseStateRegistry } from "./interfaces/IBaseStateRegistry.sol";
import { IBaseRouterImplementation } from "./interfaces/IBaseRouterImplementation.sol";
import { IPayMaster } from "./interfaces/IPayMaster.sol";
import { IPaymentHelper } from "./interfaces/IPaymentHelper.sol";
import { ISuperformFactory } from "./interfaces/ISuperformFactory.sol";
import { IBaseForm } from "./interfaces/IBaseForm.sol";
import { IBridgeValidator } from "./interfaces/IBridgeValidator.sol";
import { ISuperPositions } from "./interfaces/ISuperPositions.sol";
import { DataLib } from "./libraries/DataLib.sol";
import { Error } from "./libraries/Error.sol";
import { IPermit2 } from "./vendor/dragonfly-xyz/IPermit2.sol";
import "./crosschain-liquidity/LiquidityHandler.sol";
import "./types/DataTypes.sol";

/// @title BaseRouterImplementation
/// @author Zeropoint Labs
/// @dev Extends BaseRouter with standard internal execution functions
abstract contract BaseRouterImplementation is IBaseRouterImplementation, BaseRouter, LiquidityHandler {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev tracks the total payloads
    uint256 public payloadIds;

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct ValidateAndDispatchTokensArgs {
        LiqRequest liqRequest;
        address superform;
        uint64 srcChainId;
        uint64 dstChainId;
        address srcSender;
        bool deposit;
    }

    struct DirectDepositArgs {
        address superform;
        uint256 payloadId;
        uint256 superformId;
        uint256 amount;
        uint256 outputAmount;
        uint256 maxSlippage;
        bool retain4626;
        LiqRequest liqData;
        address receiverAddress;
        bytes extraFormData;
        uint256 msgValue;
        address srcSender;
    }

    struct SingleDepositLocalVars {
        address superform;
        uint256 shares;
    }

    struct SingleDepositArgs {
        address srcSender;
        bytes permit2data;
        address receiverAddressSP;
        InitSingleVaultData vaultData;
    }

    struct MultiDepositLocalVars {
        uint256 len;
        address[] superforms;
        uint256[] shares;
        bool[] mints;
    }

    struct MultiDepositArgs {
        address srcSender;
        bytes permit2data;
        address receiverAddressSP;
        InitMultiVaultData vaultData;
    }

    struct SingleTokenForwardLocalVars {
        IERC20 token;
        uint256 txDataLength;
        uint256 totalAmount;
        uint256 amountIn;
        uint8 bridgeId;
        address permit2;
    }

    struct MultiTokenForwardLocalVars {
        IERC20 token;
        uint256 len;
        uint256 totalAmount;
        uint256 permit2dataLen;
        uint256 targetLen;
        uint256[] amountsIn;
        uint8[] bridgeIds;
        address permit2;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) BaseRouter(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //                CORE INTERNAL FUNCTIONS                   //
    //////////////////////////////////////////////////////////////

    /// @dev getter for PERMIT2 in case it is not supported or set on a given chain
    function _getPermit2() internal view returns (address) {
        return superRegistry.PERMIT2();
    }

    /// @dev returns the address from super registry
    function _getAddress(bytes32 id_) internal view returns (address) {
        return superRegistry.getAddress(id_);
    }

    /// @dev handles same-chain single vault deposit
    function _singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req_) internal virtual {
        /// @dev validate superformData
        if (
            !_validateSuperformData(
                req_.superformData.superformId,
                req_.superformData.amount,
                req_.superformData.outputAmount,
                req_.superformData.maxSlippage,
                req_.superformData.receiverAddress,
                req_.superformData.receiverAddressSP,
                CHAIN_ID,
                true,
                ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY"))),
                false
            )
        ) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        InitSingleVaultData memory vaultData = InitSingleVaultData(
            0,
            req_.superformData.superformId,
            req_.superformData.amount,
            req_.superformData.outputAmount,
            req_.superformData.maxSlippage,
            req_.superformData.liqRequest,
            false,
            req_.superformData.retain4626,
            req_.superformData.receiverAddress,
            req_.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to Paymaster
        _directSingleDeposit(
            SingleDepositArgs(
                msg.sender, req_.superformData.permit2data, req_.superformData.receiverAddressSP, vaultData
            )
        );
        emit Completed();
    }

    /// @dev handles cross-chain single vault deposit
    function _singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req_) internal virtual {
        /// @dev validate the action
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;
        if (vars.srcChainId == req_.dstChainId) revert Error.INVALID_ACTION();

        /// @dev validate superformData
        if (
            !_validateSuperformData(
                req_.superformData.superformId,
                req_.superformData.amount,
                req_.superformData.outputAmount,
                req_.superformData.maxSlippage,
                req_.superformData.receiverAddress,
                req_.superformData.receiverAddressSP,
                req_.dstChainId,
                true,
                ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY"))),
                false
            )
        ) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        vars.currentPayloadId = ++payloadIds;

        InitSingleVaultData memory ambData = InitSingleVaultData(
            vars.currentPayloadId,
            req_.superformData.superformId,
            req_.superformData.amount,
            req_.superformData.outputAmount,
            req_.superformData.maxSlippage,
            req_.superformData.liqRequest,
            req_.superformData.hasDstSwap,
            req_.superformData.retain4626,
            req_.superformData.receiverAddress,
            req_.superformData.extraFormData
        );

        (address superform,,) = req_.superformData.superformId.getSuperform();

        (uint256 amountIn, uint8 bridgeId) =
            _singleVaultTokenForward(msg.sender, address(0), req_.superformData.permit2data, ambData, true);

        LiqRequest memory emptyRequest;

        /// @dev dispatch liquidity data
        if (
            _validateAndDispatchTokens(
                ValidateAndDispatchTokensArgs(
                    req_.superformData.liqRequest, superform, vars.srcChainId, req_.dstChainId, msg.sender, true
                )
            )
        ) emptyRequest.interimToken = req_.superformData.liqRequest.interimToken;

        /// @dev overrides user set liqData to just contain interimToken in case there is a dstSwap
        /// @dev this information is needed in case the dstSwap fails so that we can validate the interimToken in
        /// DstSwapper.sol on destination
        ambData.liqData = emptyRequest;

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
            ),
            req_.superformData.receiverAddressSP
        );

        emit CrossChainInitiatedDepositSingle(
            vars.currentPayloadId, req_.dstChainId, req_.superformData.superformId, amountIn, bridgeId, req_.ambIds
        );
    }

    /// @dev handles same-chain multi vault deposit
    function _singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req_) internal virtual {
        /// @dev validate superformData
        if (!_validateSuperformsData(req_.superformData, CHAIN_ID, true)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            0,
            req_.superformData.superformIds,
            req_.superformData.amounts,
            req_.superformData.outputAmounts,
            req_.superformData.maxSlippages,
            req_.superformData.liqRequests,
            new bool[](req_.superformData.amounts.length),
            req_.superformData.retain4626s,
            req_.superformData.receiverAddress,
            req_.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to Paymaster
        _directMultiDeposit(
            MultiDepositArgs(
                msg.sender, req_.superformData.permit2data, req_.superformData.receiverAddressSP, vaultData
            )
        );
        emit Completed();
    }

    /// @dev handles cross-chain multi vault deposit
    function _singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req_) internal virtual {
        /// @dev validate the action
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;
        if (vars.srcChainId == req_.dstChainId) revert Error.INVALID_ACTION();

        /// @dev validate superformsData
        if (!_validateSuperformsData(req_.superformsData, req_.dstChainId, true)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        vars.currentPayloadId = ++payloadIds;

        InitMultiVaultData memory ambData = InitMultiVaultData(
            vars.currentPayloadId,
            req_.superformsData.superformIds,
            req_.superformsData.amounts,
            req_.superformsData.outputAmounts,
            req_.superformsData.maxSlippages,
            req_.superformsData.liqRequests,
            req_.superformsData.hasDstSwaps,
            req_.superformsData.retain4626s,
            req_.superformsData.receiverAddress,
            req_.superformsData.extraFormData
        );

        address superform;
        uint256 len = req_.superformsData.superformIds.length;

        (uint256[] memory amountsIn, uint8[] memory bridgeIds) =
            _multiVaultTokenForward(msg.sender, new address[](0), req_.superformsData.permit2data, ambData, true);

        /// @dev empties the liqData after multiVaultTokenForward
        ambData.liqData = new LiqRequest[](len);

        /// @dev this loop is what allows to deposit to >1 different underlying on destination
        /// @dev if a loop fails in a validation the whole chain should be reverted
        for (uint256 j; j < len; ++j) {
            vars.liqRequest = req_.superformsData.liqRequests[j];

            (superform,,) = req_.superformsData.superformIds[j].getSuperform();

            /// @dev dispatch liquidity data
            if (
                _validateAndDispatchTokens(
                    ValidateAndDispatchTokensArgs(
                        vars.liqRequest, superform, vars.srcChainId, req_.dstChainId, msg.sender, true
                    )
                )
            ) ambData.liqData[j].interimToken = vars.liqRequest.interimToken;
        }

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
            ),
            req_.superformsData.receiverAddressSP
        );

        emit CrossChainInitiatedDepositMulti(
            vars.currentPayloadId, req_.dstChainId, req_.superformsData.superformIds, amountsIn, bridgeIds, req_.ambIds
        );
    }

    /// @dev handles same-chain single vault withdraw
    function _singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req_) internal virtual {
        /// @dev validate Superform data
        if (
            !_validateSuperformData(
                req_.superformData.superformId,
                req_.superformData.amount,
                req_.superformData.outputAmount,
                req_.superformData.maxSlippage,
                req_.superformData.receiverAddress,
                req_.superformData.receiverAddressSP,
                CHAIN_ID,
                false,
                ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY"))),
                false
            )
        ) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).burnSingle(
            msg.sender, req_.superformData.superformId, req_.superformData.amount
        );

        InitSingleVaultData memory vaultData = InitSingleVaultData(
            0,
            req_.superformData.superformId,
            req_.superformData.amount,
            req_.superformData.outputAmount,
            req_.superformData.maxSlippage,
            req_.superformData.liqRequest,
            false,
            req_.superformData.retain4626,
            req_.superformData.receiverAddress,
            req_.superformData.extraFormData
        );

        /// @dev same chain action
        _directSingleWithdraw(vaultData, msg.sender);
        emit Completed();
    }

    /// @dev handles cross-chain single vault withdraw
    function _singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req_) internal virtual {
        /// @dev validate the action
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;

        if (vars.srcChainId == req_.dstChainId) {
            revert Error.INVALID_ACTION();
        }

        /// @dev validate the Superforms data
        if (
            !_validateSuperformData(
                req_.superformData.superformId,
                req_.superformData.amount,
                req_.superformData.outputAmount,
                req_.superformData.maxSlippage,
                req_.superformData.receiverAddress,
                req_.superformData.receiverAddressSP,
                req_.dstChainId,
                false,
                ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY"))),
                false
            )
        ) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).burnSingle(
            msg.sender, req_.superformData.superformId, req_.superformData.amount
        );

        vars.currentPayloadId = ++payloadIds;

        InitSingleVaultData memory ambData = InitSingleVaultData(
            vars.currentPayloadId,
            req_.superformData.superformId,
            req_.superformData.amount,
            req_.superformData.outputAmount,
            req_.superformData.maxSlippage,
            req_.superformData.liqRequest,
            false,
            req_.superformData.retain4626,
            req_.superformData.receiverAddress,
            req_.superformData.extraFormData
        );

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
            ),
            req_.superformData.receiverAddressSP
        );

        emit CrossChainInitiatedWithdrawSingle(
            vars.currentPayloadId, req_.dstChainId, req_.superformData.superformId, req_.ambIds
        );
    }

    /// @dev handles same-chain multi vault withdraw
    function _singleDirectMultiVaultWithdraw(SingleDirectMultiVaultStateReq memory req_) internal virtual {
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;

        /// @dev validates the Superform data
        if (!_validateSuperformsData(req_.superformData, vars.srcChainId, false)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        /// @dev SuperPositions are burnt optimistically here
        ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).burnBatch(
            msg.sender, req_.superformData.superformIds, req_.superformData.amounts
        );

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            0,
            req_.superformData.superformIds,
            req_.superformData.amounts,
            req_.superformData.outputAmounts,
            req_.superformData.maxSlippages,
            req_.superformData.liqRequests,
            new bool[](req_.superformData.superformIds.length),
            req_.superformData.retain4626s,
            req_.superformData.receiverAddress,
            req_.superformData.extraFormData
        );

        /// @dev same chain action & forward residual payment to Paymaster
        _directMultiWithdraw(vaultData, msg.sender);
        emit Completed();
    }

    /// @dev handles cross-chain multi vault withdraw
    function _singleXChainMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req_) internal virtual {
        /// @dev validate the action
        ActionLocalVars memory vars;
        vars.srcChainId = CHAIN_ID;
        if (vars.srcChainId == req_.dstChainId) {
            revert Error.INVALID_ACTION();
        }

        /// @dev validate superformsData
        if (!_validateSuperformsData(req_.superformsData, req_.dstChainId, false)) {
            revert Error.INVALID_SUPERFORMS_DATA();
        }

        ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).burnBatch(
            msg.sender, req_.superformsData.superformIds, req_.superformsData.amounts
        );

        vars.currentPayloadId = ++payloadIds;

        InitMultiVaultData memory ambData = InitMultiVaultData(
            vars.currentPayloadId,
            req_.superformsData.superformIds,
            req_.superformsData.amounts,
            req_.superformsData.outputAmounts,
            req_.superformsData.maxSlippages,
            req_.superformsData.liqRequests,
            new bool[](req_.superformsData.amounts.length),
            req_.superformsData.retain4626s,
            req_.superformsData.receiverAddress,
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
            ),
            req_.superformsData.receiverAddressSP
        );

        emit CrossChainInitiatedWithdrawMulti(
            vars.currentPayloadId, req_.dstChainId, req_.superformsData.superformIds, req_.ambIds
        );
    }

    function _validateAndDispatchTokens(ValidateAndDispatchTokensArgs memory args_)
        internal
        virtual
        returns (bool hasDstSwap)
    {
        address bridgeValidator = superRegistry.getBridgeValidator(args_.liqRequest.bridgeId);
        /// @dev validates remaining params of txData
        hasDstSwap = IBridgeValidator(bridgeValidator).validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                args_.liqRequest.txData,
                args_.srcChainId,
                args_.dstChainId,
                args_.liqRequest.liqDstChainId,
                args_.deposit,
                args_.superform,
                args_.srcSender,
                args_.liqRequest.token,
                args_.liqRequest.interimToken
            )
        );

        /// @dev dispatches tokens through the selected liquidity bridge to the destination contract
        _dispatchTokens(
            superRegistry.getBridgeAddress(args_.liqRequest.bridgeId),
            args_.liqRequest.txData,
            args_.liqRequest.token,
            IBridgeValidator(bridgeValidator).decodeAmountIn(args_.liqRequest.txData, true),
            args_.liqRequest.nativeAmount
        );
    }

    function _dispatchAmbMessage(DispatchAMBMessageVars memory vars_, address receiverAddressSP_) internal virtual {
        uint256 txInfo = DataLib.packTxInfo(
            uint8(vars_.txType),
            uint8(CallbackType.INIT),
            vars_.multiVaults,
            STATE_REGISTRY_TYPE,
            vars_.srcSender,
            vars_.srcChainId
        );

        bytes memory ambMessage = abi.encode(AMBMessage(txInfo, vars_.ambData));

        (uint256 fees, bytes memory extraData) = IPaymentHelper(_getAddress(keccak256("PAYMENT_HELPER")))
            .calculateAMBData(vars_.dstChainId, vars_.ambIds, ambMessage);

        ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).updateTxHistory(
            vars_.currentPayloadId, txInfo, receiverAddressSP_
        );

        /// @dev this call dispatches the message to the AMB bridge through dispatchPayload
        IBaseStateRegistry(_getAddress(keccak256("CORE_STATE_REGISTRY"))).dispatchPayload{ value: fees }(
            vars_.srcSender, vars_.ambIds, vars_.dstChainId, ambMessage, extraData
        );
    }

    //////////////////////////////////////////////////////////////
    //                INTERNAL DEPOSIT HELPERS                  //
    //////////////////////////////////////////////////////////////

    /// @notice fulfils the final stage of same chain deposit action
    function _directDeposit(DirectDepositArgs memory args) internal virtual returns (uint256 shares) {
        // @dev deposits token to a given vault and mint vault positions directly through the form
        shares = IBaseForm(args.superform).directDepositIntoVault{ value: args.msgValue }(
            InitSingleVaultData(
                args.payloadId,
                args.superformId,
                args.amount,
                args.outputAmount,
                args.maxSlippage,
                args.liqData,
                false,
                args.retain4626,
                args.receiverAddress,
                // needed if user is keeping 4626
                args.extraFormData
            ),
            args.srcSender
        );
    }

    /// @notice deposits to single vault on the same chain
    /// @dev calls `_directDeposit`
    function _directSingleDeposit(SingleDepositArgs memory args_) internal virtual {
        SingleDepositLocalVars memory v;

        // @dev decode superforms
        (v.superform,,) = args_.vaultData.superformId.getSuperform();

        _singleVaultTokenForward(args_.srcSender, v.superform, args_.permit2data, args_.vaultData, false);

        // @dev deposits token to a given vault and mint vault positions.
        v.shares = _directDeposit(
            DirectDepositArgs(
                v.superform,
                args_.vaultData.payloadId,
                args_.vaultData.superformId,
                args_.vaultData.amount,
                args_.vaultData.outputAmount,
                args_.vaultData.maxSlippage,
                args_.vaultData.retain4626,
                args_.vaultData.liqData,
                args_.vaultData.receiverAddress,
                args_.vaultData.extraFormData,
                args_.vaultData.liqData.nativeAmount,
                args_.srcSender
            )
        );

        if (v.shares != 0 && !args_.vaultData.retain4626) {
            // @dev mint super positions at the end of the deposit action if user doesn't retain 4626
            ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                args_.receiverAddressSP, args_.vaultData.superformId, v.shares
            );
        }
    }

    /// @notice deposits to multiple vaults on the same chain
    /// @dev loops and call `_directDeposit`
    function _directMultiDeposit(MultiDepositArgs memory args_) internal virtual {
        MultiDepositLocalVars memory v;
        v.len = args_.vaultData.superformIds.length;

        v.superforms = new address[](v.len);
        v.shares = new uint256[](v.len);

        /// @dev decode superforms
        v.superforms = DataLib.getSuperforms(args_.vaultData.superformIds);

        _multiVaultTokenForward(args_.srcSender, v.superforms, args_.permit2data, args_.vaultData, false);

        for (uint256 i; i < v.len; ++i) {
            /// @dev deposits token to a given vault and mint vault positions.
            v.shares[i] = _directDeposit(
                DirectDepositArgs(
                    v.superforms[i],
                    args_.vaultData.payloadId,
                    args_.vaultData.superformIds[i],
                    args_.vaultData.amounts[i],
                    args_.vaultData.outputAmounts[i],
                    args_.vaultData.maxSlippages[i],
                    args_.vaultData.retain4626s[i],
                    args_.vaultData.liqData[i],
                    args_.vaultData.receiverAddress,
                    args_.vaultData.extraFormData,
                    args_.vaultData.liqData[i].nativeAmount,
                    args_.srcSender
                )
            );

            /// @dev if retain4626 is set to True, set the amount of SuperPositions to mint to 0
            if (v.shares[i] != 0 && args_.vaultData.retain4626s[i]) {
                v.shares[i] = 0;
            }
        }

        /// @dev in direct deposits, SuperPositions are minted right after depositing to vaults
        ISuperPositions(_getAddress(keccak256("SUPER_POSITIONS"))).mintBatch(
            args_.receiverAddressSP, args_.vaultData.superformIds, v.shares
        );
    }

    //////////////////////////////////////////////////////////////
    //                INTERNAL WITHDRAW HELPERS                 //
    //////////////////////////////////////////////////////////////

    /// @notice fulfils the final stage of same chain withdrawal action
    function _directWithdraw(
        address superform_,
        uint256 payloadId_,
        uint256 superformId_,
        uint256 amount_,
        uint256 outputAmount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bool retain4626_,
        address receiverAddress_,
        bytes memory extraFormData_,
        address srcSender_
    )
        internal
        virtual
    {
        /// @dev in direct withdraws, form is called directly
        IBaseForm(superform_).directWithdrawFromVault(
            InitSingleVaultData(
                payloadId_,
                superformId_,
                amount_,
                outputAmount_,
                maxSlippage_,
                liqData_,
                false,
                retain4626_,
                receiverAddress_,
                extraFormData_
            ),
            srcSender_
        );
    }

    /// @notice withdraws from single vault on the same chain
    /// @dev call `_directWithdraw`
    function _directSingleWithdraw(InitSingleVaultData memory vaultData_, address srcSender_) internal virtual {
        /// @dev decode superforms
        (address superform,,) = vaultData_.superformId.getSuperform();

        _directWithdraw(
            superform,
            vaultData_.payloadId,
            vaultData_.superformId,
            vaultData_.amount,
            vaultData_.outputAmount,
            vaultData_.maxSlippage,
            vaultData_.liqData,
            vaultData_.retain4626,
            vaultData_.receiverAddress,
            vaultData_.extraFormData,
            srcSender_
        );
    }

    /// @notice withdraws from multiple vaults on the same chain
    /// @dev loops and call `_directWithdraw`
    function _directMultiWithdraw(InitMultiVaultData memory vaultData_, address srcSender_) internal virtual {
        /// @dev decode superforms
        address[] memory superforms = DataLib.getSuperforms(vaultData_.superformIds);
        uint256 len = superforms.length;

        for (uint256 i; i < len; ++i) {
            /// @dev deposits token to a given vault and mint vault positions.
            _directWithdraw(
                superforms[i],
                vaultData_.payloadId,
                vaultData_.superformIds[i],
                vaultData_.amounts[i],
                vaultData_.outputAmounts[i],
                vaultData_.maxSlippages[i],
                vaultData_.liqData[i],
                vaultData_.retain4626s[i],
                vaultData_.receiverAddress,
                vaultData_.extraFormData,
                srcSender_
            );
        }
    }

    function _forwardDustToPaymaster(address token_) internal {
        if (token_ == address(0)) revert Error.ZERO_ADDRESS();

        address paymaster = _getAddress(keccak256("PAYMASTER"));
        IERC20 token = IERC20(token_);

        uint256 dust = token.balanceOf(address(this));
        if (dust != 0) {
            token.safeTransfer(paymaster, dust);
            emit RouterDustForwardedToPaymaster(token_, dust);
        }
    }

    //////////////////////////////////////////////////////////////
    //               INTERNAL VALIDATION HELPERS                //
    //////////////////////////////////////////////////////////////

    function _validateSuperformData(
        uint256 superformId_,
        uint256 amount_,
        uint256 outputAmount_,
        uint256 maxSlippage_,
        address receiverAddress_,
        address receiverAddressSP_,
        uint64 dstChainId_,
        bool isDeposit_,
        ISuperformFactory factory_,
        bool multi_
    )
        internal
        virtual
        returns (bool)
    {
        /// @dev if same chain, validate if the superform exists on factory
        if (dstChainId_ == CHAIN_ID && !factory_.isSuperform(superformId_)) {
            return false;
        }

        /// @dev the dstChainId_ (in the state request) must match the superforms' chainId (superform must exist on
        /// destination)
        (, uint32 formImplementationId, uint64 sfDstChainId) = superformId_.getSuperform();

        if (dstChainId_ != sfDstChainId) return false;

        /// @dev 10000 = 100% slippage
        if (maxSlippage_ > 10_000) return false;

        /// @dev amounts can't be 0
        if (amount_ == 0 || outputAmount_ == 0) return false;

        /// @dev only validate this for non multi case (multi case is validated in _validateSuperformsData)
        /// @dev ensure that receiver address is set always
        /// @dev in deposits, this is important for receive4626 (on destination). It is also important for refunds on
        /// destination
        /// @dev in withdraws, this is important for the user to receive their tokens in the liqDstChainId
        if (!multi_ && receiverAddress_ == address(0)) {
            return false;
        }

        /// @dev redundant check on same chain, but helpful on xchain actions to halt deposits earlier
        if (isDeposit_) {
            if (factory_.isFormImplementationPaused(formImplementationId)) {
                return false;
            }

            /// @dev only validate this for non multi case (multi case is validated in _validateSuperformsData)
            if (!multi_) {
                if (receiverAddressSP_ == address(0)) {
                    return false;
                } else {
                    /// @dev if receiverAddressSP_ is set and is a contract, it must implement onERC1155Received
                    _doSafeTransferAcceptanceCheck(receiverAddressSP_);
                }
            }
        }

        /// if it reaches this point then is valid
        return true;
    }

    function _validateSuperformsData(
        MultiVaultSFData memory superformsData_,
        uint64 dstChainId_,
        bool deposit_
    )
        internal
        virtual
        returns (bool)
    {
        uint256 len = superformsData_.amounts.length;
        uint256 lenSuperforms = superformsData_.superformIds.length;
        uint256 liqRequestsLen = superformsData_.liqRequests.length;

        /// @dev empty requests are not allowed, as well as requests with length mismatch
        if (len == 0 || liqRequestsLen == 0) return false;
        if (len != liqRequestsLen) return false;

        /// @dev all other length checks
        if (
            lenSuperforms != len || lenSuperforms != superformsData_.outputAmounts.length
                || lenSuperforms != superformsData_.maxSlippages.length
                || lenSuperforms != superformsData_.hasDstSwaps.length
                || lenSuperforms != superformsData_.retain4626s.length
        ) {
            return false;
        }

        /// @dev deposits beyond multi vault limit for a given destination chain blocked
        if (lenSuperforms > superRegistry.getVaultLimitPerDestination(dstChainId_)) {
            return false;
        }

        /// @dev since this is a multi case, validate receiverAddress here once
        if (superformsData_.receiverAddress == address(0)) {
            return false;
        }

        /// @dev since this is a multi case, validate receiverAddressSP here once
        if (deposit_) {
            if (superformsData_.receiverAddressSP == address(0)) {
                return false;
            } else {
                /// @dev if receiverAddressSP_ is set and is a contract, it must implement onERC1155Received
                _doSafeTransferAcceptanceCheck(superformsData_.receiverAddressSP);
            }
        }

        ISuperformFactory factory = ISuperformFactory(_getAddress(keccak256("SUPERFORM_FACTORY")));
        bool valid;

        /// @dev slippage, amount, paused status validation
        for (uint256 i; i < len; ++i) {
            valid = _validateSuperformData(
                superformsData_.superformIds[i],
                superformsData_.amounts[i],
                superformsData_.outputAmounts[i],
                superformsData_.maxSlippages[i],
                superformsData_.receiverAddress,
                superformsData_.receiverAddressSP,
                dstChainId_,
                deposit_,
                factory,
                true
            );

            if (!valid) {
                return valid;
            }

            /// @dev ensure interimTokens aren't repeated on destination chains
            address interimToken = superformsData_.liqRequests[i].interimToken;
            if (interimToken != address(0)) {
                for (uint256 j; j < i; ++j) {
                    if (j != i) {
                        if (interimToken == superformsData_.liqRequests[j].interimToken) {
                            return false;
                        }
                    }
                }
            }
        }

        return true;
    }

    //////////////////////////////////////////////////////////////
    //             INTERNAL FEE FORWARDING HELPERS              //
    //////////////////////////////////////////////////////////////

    /// @dev forwards the residual payment to Paymaster
    function _forwardPayment(uint256 _balanceBefore) internal virtual {
        /// @dev deducts what's already available sends what's left in msg.value to Paymaster
        uint256 residualPayment = address(this).balance - _balanceBefore;

        if (residualPayment != 0) {
            IPayMaster(_getAddress(keccak256("PAYMASTER"))).makePayment{ value: residualPayment }(msg.sender);
        }
    }

    //////////////////////////////////////////////////////////////
    //       INTERNAL SAME CHAIN TOKEN SETTLEMENT HELPERS       //
    //////////////////////////////////////////////////////////////

    function _singleVaultTokenForward(
        address srcSender_,
        address target_,
        bytes memory permit2data_,
        InitSingleVaultData memory vaultData_,
        bool xChain
    )
        internal
        virtual
        returns (uint256, uint8)
    {
        SingleTokenForwardLocalVars memory v;

        v.bridgeId = vaultData_.liqData.bridgeId;

        v.txDataLength = vaultData_.liqData.txData.length;

        if (v.txDataLength == 0 && xChain) {
            revert Error.NO_TXDATA_PRESENT();
        }

        if (v.txDataLength != 0) {
            v.amountIn = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeId)).decodeAmountIn(
                vaultData_.liqData.txData, false
            );
        } else {
            v.amountIn = vaultData_.amount;
        }

        if (vaultData_.liqData.token != NATIVE) {
            v.token = IERC20(vaultData_.liqData.token);

            if (permit2data_.length != 0) {
                v.permit2 = _getPermit2();

                (uint256 nonce, uint256 deadline, bytes memory signature) =
                    abi.decode(permit2data_, (uint256, uint256, bytes));

                /// @dev moves the tokens from the user to the router

                IPermit2(v.permit2).permitTransferFrom(
                    // The permit message.
                    IPermit2.PermitTransferFrom({
                        permitted: IPermit2.TokenPermissions({ token: v.token, amount: v.amountIn }),
                        nonce: nonce,
                        deadline: deadline
                    }),
                    // The transfer recipient and amount.
                    IPermit2.SignatureTransferDetails({ to: address(this), requestedAmount: v.amountIn }),
                    // The owner of the tokens, which must also be
                    // the signer of the message, otherwise this call
                    // will fail.
                    srcSender_,
                    // The packed signature that was the result of signing
                    // the EIP712 hash of `permit`.
                    signature
                );
            } else {
                if (v.token.allowance(srcSender_, address(this)) < v.amountIn) {
                    revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
                }

                /// @dev moves the tokens from the user to the router
                v.token.safeTransferFrom(srcSender_, address(this), v.amountIn);
            }

            if (target_ != address(0)) {
                /// @dev approves the input amount to the target
                v.token.safeIncreaseAllowance(target_, v.amountIn);
            }
        }

        return (v.amountIn, v.bridgeId);
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
        returns (uint256[] memory, uint8[] memory)
    {
        MultiTokenForwardLocalVars memory v;

        address token = vaultData_.liqData[0].token;
        v.len = vaultData_.liqData.length;

        v.amountsIn = new uint256[](v.len);
        v.bridgeIds = new uint8[](v.len);

        for (uint256 i; i < v.len; ++i) {
            v.bridgeIds[i] = vaultData_.liqData[i].bridgeId;
            if (vaultData_.liqData[i].txData.length != 0) {
                v.amountsIn[i] = IBridgeValidator(superRegistry.getBridgeValidator(v.bridgeIds[i])).decodeAmountIn(
                    vaultData_.liqData[i].txData, false
                );
            } else {
                v.amountsIn[i] = vaultData_.amounts[i];
            }
        }

        if (token != NATIVE) {
            v.token = IERC20(token);

            v.permit2dataLen = permit2data_.length;

            for (uint256 i; i < v.len; ++i) {
                if (vaultData_.liqData[i].token != address(v.token)) {
                    revert Error.INVALID_DEPOSIT_TOKEN();
                }

                uint256 txDataLength = vaultData_.liqData[i].txData.length;
                if (txDataLength == 0 && xChain) {
                    revert Error.NO_TXDATA_PRESENT();
                }

                v.totalAmount += v.amountsIn[i];
            }

            if (v.totalAmount == 0) {
                revert Error.ZERO_AMOUNT();
            }

            if (v.permit2dataLen != 0) {
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
                    revert Error.INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();
                }

                /// @dev moves the tokens from the user to the router
                v.token.safeTransferFrom(srcSender_, address(this), v.totalAmount);
            }

            /// @dev approves individual final targets if needed here
            v.targetLen = targets_.length;
            for (uint256 j; j < v.targetLen; ++j) {
                /// @dev approves the superform
                v.token.safeIncreaseAllowance(targets_[j], v.amountsIn[j]);
            }
        }

        return (v.amountsIn, v.bridgeIds);
    }

    /// @dev implementation copied from OpenZeppelin 5.0 and stripped down
    function _doSafeTransferAcceptanceCheck(address to) private view {
        if (to.code.length > 0) {
            try IERC165(to).supportsInterface(type(IERC1155Receiver).interfaceId) returns (bool supported) {
                if (!supported) revert IERC1155Errors.ERC1155InvalidReceiver(to);
            } catch {
                revert IERC1155Errors.ERC1155InvalidReceiver(to);
            }
        }
    }
}
