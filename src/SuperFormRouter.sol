/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBaseStateRegistry} from "./interfaces/IBaseStateRegistry.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperFormRouter} from "./interfaces/ISuperFormRouter.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {IFormBeacon} from "./interfaces/IFormBeacon.sol";
import {IBridgeValidator} from "./interfaces/IBridgeValidator.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import {LiquidityHandler} from "./crosschain-liquidity/LiquidityHandler.sol";
import {DataLib} from "./libraries/DataLib.sol";
import {Error} from "./utils/Error.sol";
import "./types/DataTypes.sol";

/// @title SuperFormRouter
/// @author Zeropoint Labs.
/// @dev Routes users funds and action information to a remote execution chain.
/// @dev extends Liquidity Handler.
contract SuperFormRouter is ISuperFormRouter, LiquidityHandler {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    /*///////////////////////////////////////////////////////////////
                             CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint8 public constant STATE_REGISTRY_TYPE = 1;
    ISuperRegistry public immutable superRegistry;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @dev prevents fee transfer in between a multi dst tx
    bool public isTxOngoing;

    /// @dev tracks the total payloads
    uint256 public override payloadIds;

    /*///////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyProtocolAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(msg.sender)) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasEmergencyAdminRole(msg.sender))
            revert Error.NOT_EMERGENCY_ADMIN();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @notice liquidity bridge tech fails without a native receive function.
    receive() external payable {}

    /// @inheritdoc ISuperFormRouter
    function multiDstMultiVaultDeposit(MultiDstMultiVaultsStateReq calldata req) external payable override {
        /// @dev sets here to prevent fee forwarding in children functions
        isTxOngoing = true;

        uint256 chainId = superRegistry.chainId();

        for (uint256 i; i < req.dstChainIds.length; ) {
            if (chainId == req.dstChainIds[i]) {
                singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq(req.superFormsData[i]));
            } else {
                singleXChainMultiVaultDeposit(
                    SingleXChainMultiVaultStateReq(
                        req.ambIds[i],
                        req.dstChainIds[i],
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            }
            unchecked {
                ++i;
            }
        }

        /// @dev resets here to forward fees
        delete isTxOngoing;
        _forwardFee();
    }

    /// @inheritdoc ISuperFormRouter
    function multiDstSingleVaultDeposit(MultiDstSingleVaultStateReq calldata req) external payable override {
        uint64 srcChainId = superRegistry.chainId();
        uint64 dstChainId;

        /// @dev sets here to prevent fee forwarding in children functions
        isTxOngoing = true;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            dstChainId = req.dstChainIds[i];
            if (srcChainId == dstChainId) {
                singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq(req.superFormsData[i]));
            } else {
                singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(
                        req.ambIds[i],
                        dstChainId,
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            }
        }

        /// @dev resets here to forward fees
        delete isTxOngoing;
        _forwardFee();
    }

    /// @inheritdoc ISuperFormRouter
    function singleXChainMultiVaultDeposit(SingleXChainMultiVaultStateReq memory req) public payable override {
        /// @dev validate superFormsData
        if (!_validateSuperFormsDepositData(req.superFormsData, req.dstChainId)) revert Error.INVALID_SUPERFORMS_DATA();

        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            vars.currentPayloadId,
            req.superFormsData.superFormIds,
            req.superFormsData.amounts,
            req.superFormsData.maxSlippages,
            new LiqRequest[](0),
            req.superFormsData.extraFormData
        );

        address permit2 = superRegistry.PERMIT2();
        address superForm;

        /// @dev this loop is what allows to deposit to >1 different underlying on destination
        /// @dev if a loop fails in a validation the whole chain should be reverted
        for (uint256 j = 0; j < req.superFormsData.liqRequests.length; j++) {
            vars.liqRequest = req.superFormsData.liqRequests[j];
            /// @dev dispatch liquidity data
            (superForm, , ) = req.superFormsData.superFormIds[j].getSuperForm();

            _validateAndDispatchTokens(
                vars.liqRequest,
                permit2,
                superForm,
                vars.srcChainId,
                req.dstChainId,
                msg.sender,
                true
            );
        }

        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.DEPOSIT,
                abi.encode(ambData),
                req.superFormsData.superFormIds,
                req.extraData,
                msg.sender,
                req.ambIds,
                1,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        _forwardFee();
        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @inheritdoc ISuperFormRouter
    function singleXChainSingleVaultDeposit(SingleXChainSingleVaultStateReq memory req) public payable override {
        ActionLocalVars memory vars;

        vars.srcChainId = superRegistry.chainId();
        if (vars.srcChainId == req.dstChainId) revert Error.INVALID_CHAIN_IDS();

        InitSingleVaultData memory ambData;
        (ambData, vars.currentPayloadId) = _buildDepositAmbData(req.dstChainId, req.superFormData, true);

        vars.liqRequest = req.superFormData.liqRequest;
        (address superForm, , ) = req.superFormData.superFormId.getSuperForm();

        _validateAndDispatchTokens(
            vars.liqRequest,
            superRegistry.PERMIT2(),
            superForm,
            vars.srcChainId,
            req.dstChainId,
            msg.sender,
            true
        );

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = req.superFormData.superFormId;

        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.DEPOSIT,
                abi.encode(ambData),
                superFormIds,
                req.extraData,
                msg.sender,
                req.ambIds,
                0,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        _forwardFee();
        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @inheritdoc ISuperFormRouter
    function singleDirectSingleVaultDeposit(SingleDirectSingleVaultStateReq memory req) public payable override {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();

        InitSingleVaultData memory vaultData;
        (vaultData, vars.currentPayloadId) = _buildDepositAmbData(vars.srcChainId, req.superFormData, false);

        /// @dev same chain action & forward residual fee to fee collector
        _directSingleDeposit(msg.sender, vaultData);
        _forwardFee();

        emit Completed(vars.currentPayloadId);
    }

    /// @inheritdoc ISuperFormRouter
    function singleDirectMultiVaultDeposit(SingleDirectMultiVaultStateReq memory req) public payable override {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();
        vars.currentPayloadId = ++payloadIds;

        InitMultiVaultData memory vaultData = InitMultiVaultData(
            vars.currentPayloadId,
            req.superFormData.superFormIds,
            req.superFormData.amounts,
            req.superFormData.maxSlippages,
            req.superFormData.liqRequests,
            req.superFormData.extraFormData
        );

        /// @dev same chain action & forward residual fee to fee collector
        _directMultiDeposit(msg.sender, vaultData);
        _forwardFee();

        emit Completed(vars.currentPayloadId);
    }

    /// @inheritdoc ISuperFormRouter
    function multiDstMultiVaultWithdraw(MultiDstMultiVaultsStateReq calldata req) external payable override {
        /// @dev sets here to prevent fee forwarding in children functions
        isTxOngoing = true;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            singleDstMultiVaultWithdraw(
                SingleXChainMultiVaultStateReq(
                    req.ambIds[i],
                    req.dstChainIds[i],
                    req.superFormsData[i],
                    req.extraDataPerDst[i]
                )
            );
        }

        /// @dev resets here to forward fees
        delete isTxOngoing;
        _forwardFee();
    }

    /// @inheritdoc ISuperFormRouter
    function singleDstMultiVaultWithdraw(SingleXChainMultiVaultStateReq memory req) public payable override {
        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;

        vars.srcChainId = superRegistry.chainId();

        /// @dev validate superFormsData
        if (!_validateSuperFormsWithdrawData(req.superFormsData, req.dstChainId))
            revert Error.INVALID_SUPERFORMS_DATA();

        ISuperPositions(superRegistry.superPositions()).burnBatchSP(
            msg.sender,
            req.superFormsData.superFormIds,
            req.superFormsData.amounts
        );

        vars.currentPayloadId = ++payloadIds;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            vars.currentPayloadId,
            req.superFormsData.superFormIds,
            req.superFormsData.amounts,
            req.superFormsData.maxSlippages,
            req.superFormsData.liqRequests,
            req.superFormsData.extraFormData
        );

        /// @dev same chain action
        if (vars.srcChainId == req.dstChainId) {
            _directMultiWithdraw(req.superFormsData.liqRequests, ambData, msg.sender);
            emit Completed(vars.currentPayloadId);
        } else {
            _dispatchAmbMessage(
                DispatchAMBMessageVars(
                    TransactionType.WITHDRAW,
                    abi.encode(ambData),
                    req.superFormsData.superFormIds,
                    req.extraData,
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

        _forwardFee();
    }

    /// @inheritdoc ISuperFormRouter
    function multiDstSingleVaultWithdraw(MultiDstSingleVaultStateReq calldata req) external payable override {
        uint64 dstChainId;

        /// @dev sets here to prevent fee forwarding in children functions
        isTxOngoing = true;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            dstChainId = req.dstChainIds[i];
            if (superRegistry.chainId() == dstChainId) {
                singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq(req.superFormsData[i]));
            } else {
                singleXChainSingleVaultWithdraw(
                    SingleXChainSingleVaultStateReq(
                        req.ambIds[i],
                        dstChainId,
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            }
        }

        /// @dev resets here to forward fee
        delete isTxOngoing;
        _forwardFee();
    }

    /// @inheritdoc ISuperFormRouter
    function singleXChainSingleVaultWithdraw(SingleXChainSingleVaultStateReq memory req) public payable override {
        ActionLocalVars memory vars;

        vars.srcChainId = superRegistry.chainId();

        if (vars.srcChainId == req.dstChainId) revert Error.INVALID_CHAIN_IDS();

        InitSingleVaultData memory ambData;

        (ambData, vars.currentPayloadId) = _buildWithdrawAmbData(msg.sender, req.dstChainId, req.superFormData);

        uint256[] memory superFormIds = new uint256[](1);
        superFormIds[0] = req.superFormData.superFormId;

        _dispatchAmbMessage(
            DispatchAMBMessageVars(
                TransactionType.WITHDRAW,
                abi.encode(ambData),
                superFormIds,
                req.extraData,
                msg.sender,
                req.ambIds,
                0,
                vars.srcChainId,
                req.dstChainId,
                vars.currentPayloadId
            )
        );

        _forwardFee();
        emit CrossChainInitiated(vars.currentPayloadId);
    }

    /// @inheritdoc ISuperFormRouter
    function singleDirectSingleVaultWithdraw(SingleDirectSingleVaultStateReq memory req) public payable override {
        ActionLocalVars memory vars;
        vars.srcChainId = superRegistry.chainId();

        InitSingleVaultData memory ambData;

        (ambData, vars.currentPayloadId) = _buildWithdrawAmbData(msg.sender, vars.srcChainId, req.superFormData);

        /// @dev same chain action
        _directSingleWithdraw(req.superFormData.liqRequest, ambData, msg.sender);

        _forwardFee();
        emit Completed(vars.currentPayloadId);
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _buildDepositAmbData(
        uint64 dstChainId_,
        SingleVaultSFData memory superFormData_,
        bool emptyLiqReq
    ) internal returns (InitSingleVaultData memory ambData, uint256 currentPayloadId) {
        /// @dev validate superFormsData
        if (!_validateSuperFormData(dstChainId_, superFormData_)) revert Error.INVALID_SUPERFORMS_DATA();

        if (
            !IBridgeValidator(superRegistry.getBridgeValidator(superFormData_.liqRequest.bridgeId))
                .validateTxDataAmount(superFormData_.liqRequest.txData, superFormData_.amount)
        ) revert Error.INVALID_TXDATA_AMOUNTS();

        currentPayloadId = ++payloadIds;
        LiqRequest memory emptyRequest;

        ambData = InitSingleVaultData(
            currentPayloadId,
            superFormData_.superFormId,
            superFormData_.amount,
            superFormData_.maxSlippage,
            emptyLiqReq ? emptyRequest : superFormData_.liqRequest,
            superFormData_.extraFormData
        );
    }

    function _buildWithdrawAmbData(
        address srcSender_,
        uint64 dstChainId_,
        SingleVaultSFData memory superFormData_
    ) internal returns (InitSingleVaultData memory ambData, uint256 currentPayloadId) {
        /// @dev validate superFormsData
        if (!_validateSuperFormData(dstChainId_, superFormData_)) revert Error.INVALID_SUPERFORMS_DATA();

        ISuperPositions(superRegistry.superPositions()).burnSingleSP(
            srcSender_,
            superFormData_.superFormId,
            superFormData_.amount
        );

        currentPayloadId = ++payloadIds;

        ambData = InitSingleVaultData(
            currentPayloadId,
            superFormData_.superFormId,
            superFormData_.amount,
            superFormData_.maxSlippage,
            superFormData_.liqRequest,
            superFormData_.extraFormData
        );
    }

    function _validateAndDispatchTokens(
        LiqRequest memory liqRequest_,
        address permit2_,
        address superForm_,
        uint64 srcChainId_,
        uint64 dstChainId_,
        address srcSender_,
        bool deposit_
    ) internal {
        IBridgeValidator(superRegistry.getBridgeValidator(liqRequest_.bridgeId)).validateTxData(
            liqRequest_.txData,
            srcChainId_,
            dstChainId_,
            deposit_,
            superForm_,
            srcSender_,
            liqRequest_.token
        );
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

    struct DispatchAMBMessageVars {
        TransactionType txType;
        bytes ambData;
        uint256[] superFormIds;
        bytes extraData;
        address srcSender;
        uint8[] ambIds;
        uint8 multiVaults;
        uint64 srcChainId;
        uint64 dstChainId;
        uint256 currentPayloadId;
    }

    function _dispatchAmbMessage(DispatchAMBMessageVars memory vars) internal {
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
        SingleDstAMBParams memory ambParams = abi.decode(vars.extraData, (SingleDstAMBParams));

        /// @dev _liqReq should have path encoded for withdraw to SuperFormRouter on chain different than chainId
        /// @dev construct txData in this fashion: from FTM SOURCE send message to BSC DESTINATION
        /// @dev so that BSC DISPATCHTOKENS sends tokens to AVAX receiver (EOA/contract/user-specified)
        /// @dev sync could be a problem, how long Socket path stays vaild vs. how fast we bridge/receive on Dst
        IBaseStateRegistry(superRegistry.coreStateRegistry()).dispatchPayload{value: ambParams.gasToPay}(
            vars.srcSender,
            vars.ambIds,
            vars.dstChainId,
            abi.encode(ambMessage),
            ambParams.encodedAMBExtraData
        );

        ISuperPositions(superRegistry.superPositions()).updateTxHistory(vars.currentPayloadId, ambMessage.txInfo);
    }

    /*///////////////////////////////////////////////////////////////
                            DEPOSIT HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice deposits to single vault on the same chain
    /// @dev calls `_directDeposit`
    function _directSingleDeposit(address srcSender_, InitSingleVaultData memory vaultData_) internal {
        address superForm;
        uint256 dstAmount;

        /// @dev decode superforms
        (superForm, , ) = vaultData_.superFormId.getSuperForm();

        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            superForm,
            vaultData_.payloadId,
            vaultData_.superFormId,
            vaultData_.amount,
            vaultData_.maxSlippage,
            vaultData_.liqData,
            vaultData_.extraFormData,
            vaultData_.liqData.nativeAmount,
            srcSender_
        );

        ISuperPositions(superRegistry.superPositions()).mintSingleSP(srcSender_, vaultData_.superFormId, dstAmount);
    }

    /// @notice deposits to multiple vaults on the same chain
    /// @dev loops and call `_directDeposit`
    function _directMultiDeposit(address srcSender_, InitMultiVaultData memory vaultData_) internal {
        uint256 len = vaultData_.superFormIds.length;

        address[] memory superForms = new address[](len);
        uint256[] memory dstAmounts = new uint256[](len);

        /// @dev decode superforms
        (superForms, , ) = DataLib.getSuperForms(vaultData_.superFormIds);

        for (uint256 i; i < len; ) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            dstAmounts[i] = _directDeposit(
                superForms[i],
                vaultData_.payloadId,
                vaultData_.superFormIds[i],
                vaultData_.amounts[i],
                vaultData_.maxSlippage[i],
                vaultData_.liqData[i],
                vaultData_.extraFormData,
                vaultData_.liqData[i].nativeAmount, /// @dev FIXME: is this acceptable ? Note that the user fully controls the msg.value being sent
                srcSender_
            );

            unchecked {
                ++i;
            }
        }

        /// @dev TEST-CASE: msg.sender to whom we mint. use passed `admin` arg?
        ISuperPositions(superRegistry.superPositions()).mintBatchSP(srcSender_, vaultData_.superFormIds, dstAmounts);
    }

    /// @notice fulfils the final stage of same chain deposit action
    function _directDeposit(
        address superForm,
        uint256 payloadId_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_,
        uint256 msgValue_,
        address srcSender_
    ) internal returns (uint256 dstAmount) {
        /// @dev validates if superFormId exists on factory
        (, , uint64 chainId) = ISuperFormFactory(superRegistry.superFormFactory()).getSuperForm(superFormId_);

        if (chainId != superRegistry.chainId()) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev deposits collateral to a given vault and mint vault positions.
        /// @dev FIXME: in multi deposits we split the msg.value, but this only works if we validate that the user is only depositing from one source asset (native in this case)
        dstAmount = IBaseForm(superForm).directDepositIntoVault{value: msgValue_}(
            InitSingleVaultData(payloadId_, superFormId_, amount_, maxSlippage_, liqData_, extraFormData_),
            srcSender_
        );
    }

    /*///////////////////////////////////////////////////////////////
                            WITHDRAW HELPERS
    //////////////////////////////////////////////////////////////*/

    function _directWithdraw(
        address superForm,
        uint256 txData_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_,
        address srcSender_
    ) internal {
        /// @dev validates if superFormId exists on factory
        (, , uint64 chainId) = ISuperFormFactory(superRegistry.superFormFactory()).getSuperForm(superFormId_);

        if (chainId != superRegistry.chainId()) {
            revert Error.INVALID_CHAIN_ID();
        }

        /// @dev to allow bridging somewhere else requires arch change
        IBaseForm(superForm).directWithdrawFromVault(
            InitSingleVaultData(txData_, superFormId_, amount_, maxSlippage_, liqData_, extraFormData_),
            srcSender_
        );
    }

    /**
     * @notice withdraw() to vaults existing on the same chain as SuperFormRouter
     * @dev Optimistic transfer & call
     */
    function _directSingleWithdraw(
        LiqRequest memory liqRequest_,
        InitSingleVaultData memory ambData_,
        address srcSender_
    ) internal {
        /// @dev decode superforms
        (address superForm, , ) = ambData_.superFormId.getSuperForm();

        _directWithdraw(
            superForm,
            ambData_.payloadId,
            ambData_.superFormId,
            ambData_.amount,
            ambData_.maxSlippage,
            liqRequest_,
            ambData_.extraFormData,
            srcSender_
        );
    }

    /**
     * @notice withdraw() to vaults existing on the same chain as SuperFormRouter
     * @dev Optimistic transfer & call
     */
    function _directMultiWithdraw(
        LiqRequest[] memory liqRequests_,
        InitMultiVaultData memory ambData_,
        address srcSender_
    ) internal {
        /// @dev decode superforms
        (address[] memory superForms, , ) = DataLib.getSuperForms(ambData_.superFormIds);

        for (uint256 i = 0; i < superForms.length; i++) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            _directWithdraw(
                superForms[i],
                ambData_.payloadId,
                ambData_.superFormIds[i],
                ambData_.amounts[i],
                ambData_.maxSlippage[i],
                liqRequests_[i],
                ambData_.extraFormData,
                srcSender_
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            VALIDATION HELPERS
    //////////////////////////////////////////////////////////////*/

    function _validateSuperFormData(
        uint64 dstChainId_,
        SingleVaultSFData memory superFormData_
    ) internal view returns (bool) {
        if (dstChainId_ != DataLib.getDestinationChain(superFormData_.superFormId)) return false;

        if (superFormData_.maxSlippage > 10000) return false;

        (, uint32 formBeaconId_, ) = superFormData_.superFormId.getSuperForm();

        return !IFormBeacon(ISuperFormFactory(superRegistry.superFormFactory()).getFormBeacon(formBeaconId_)).paused();
    }

    function _validateSuperFormsDepositData(
        MultiVaultSFData memory superFormsData_,
        uint64 dstChainId
    ) internal view returns (bool) {
        uint256 len = superFormsData_.amounts.length;
        uint256 liqRequestsLen = superFormsData_.liqRequests.length;

        if (len == 0 || liqRequestsLen == 0) return false;
        if (len != liqRequestsLen) return false;

        /// @dev sizes validation
        if (
            !(superFormsData_.superFormIds.length == superFormsData_.amounts.length &&
                superFormsData_.superFormIds.length == superFormsData_.maxSlippages.length)
        ) {
            return false;
        }

        /// @dev slippage and paused validation
        bool txDataAmountValid;
        for (uint256 i = 0; i < len; i++) {
            if (superFormsData_.maxSlippages[i] > 10000) return false;
            (, uint32 formBeaconId_, uint64 sfDstChainId) = superFormsData_.superFormIds[i].getSuperForm();
            if (dstChainId != sfDstChainId) return false;

            if (IFormBeacon(ISuperFormFactory(superRegistry.superFormFactory()).getFormBeacon(formBeaconId_)).paused())
                return false;

            txDataAmountValid = IBridgeValidator(
                superRegistry.getBridgeValidator(superFormsData_.liqRequests[i].bridgeId)
            ).validateTxDataAmount(superFormsData_.liqRequests[i].txData, superFormsData_.amounts[i]);

            if (!txDataAmountValid) return false;
        }

        return true;
    }

    function _validateSuperFormsWithdrawData(
        MultiVaultSFData memory superFormsData_,
        uint64 dstChainId
    ) internal view returns (bool) {
        uint256 len = superFormsData_.amounts.length;
        uint256 liqRequestsLen = superFormsData_.liqRequests.length;

        if (len == 0 || liqRequestsLen == 0) return false;

        /// @dev sizes validation
        /// @dev In multiVault withdraws, the number of liq requests must be equal to number of target vaults
        if (liqRequestsLen != len) {
            return false;
        }

        if (
            !(superFormsData_.superFormIds.length == superFormsData_.amounts.length &&
                superFormsData_.superFormIds.length == superFormsData_.maxSlippages.length)
        ) {
            return false;
        }

        /// @dev slippage and paused validation
        for (uint256 i; i < len; ) {
            if (superFormsData_.maxSlippages[i] > 10000) return false;
            (, uint32 formBeaconId_, uint64 sfDstChainId) = superFormsData_.superFormIds[i].getSuperForm();
            if (dstChainId != sfDstChainId) return false;

            if (IFormBeacon(ISuperFormFactory(superRegistry.superFormFactory()).getFormBeacon(formBeaconId_)).paused())
                return false;

            unchecked {
                ++i;
            }
        }

        return true;
    }

    /// @dev forwards the residual fees to fee collector
    function _forwardFee() internal {
        uint256 residualFee = address(this).balance;

        if (residualFee > 0 && !isTxOngoing) {
            IFeeCollector(superRegistry.getFeeCollector()).makePayment{value: residualFee}(msg.sender);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev EMERGENCY_ADMIN ONLY FUNCTION.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    function emergencyWithdrawToken(address tokenContract_, uint256 amount_) external onlyEmergencyAdmin {
        IERC20 tokenContract = IERC20(tokenContract_);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(msg.sender, amount_);
    }

    /// @dev EMERGENCY_ADMIN ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function emergencyWithdrawNativeToken(uint256 amount_) external onlyEmergencyAdmin {
        (bool success, ) = payable(msg.sender).call{value: amount_}("");
        if (!success) revert Error.NATIVE_TOKEN_TRANSFER_FAILURE();
    }
}
