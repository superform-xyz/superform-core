/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {LiqRequest, TransactionType, CallbackType, MultiVaultsSFData, SingleVaultSFData, MultiDstMultiVaultsStateReq, SingleDstMultiVaultsStateReq, MultiDstSingleVaultStateReq, SingleXChainSingleVaultStateReq, SingleDirectSingleVaultStateReq, InitMultiVaultData, InitSingleVaultData, AMBMessage, SingleDstAMBParams} from "./types/DataTypes.sol";
import {IBaseStateRegistry} from "./interfaces/IBaseStateRegistry.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperRouter} from "./interfaces/ISuperRouter.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {IFormBeacon} from "./interfaces/IFormBeacon.sol";
import {IBridgeValidator} from "./interfaces/IBridgeValidator.sol";
import {LiquidityHandler} from "./crosschain-liquidity/LiquidityHandler.sol";
import {Error} from "./utils/Error.sol";
import {ISuperPositions} from "./interfaces/ISuperPositions.sol";
import "./utils/DataPacking.sol";

/// @title Super Router
/// @author Zeropoint Labs.
/// @dev Routes users funds and deposit information to a remote execution chain.
/// @dev extends Liquidity Handler.
contract SuperRouter is ISuperRouter, LiquidityHandler {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////*/

    uint8 public constant STATE_REGISTRY_TYPE = 1;

    ISuperRegistry public immutable superRegistry;

    uint80 public totalTransactions;

    modifier onlyProtocolAdmin() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasProtocolAdminRole(
                msg.sender
            )
        ) revert Error.NOT_PROTOCOL_ADMIN();
        _;
    }

    modifier onlyBank() {
        if (msg.sender != superRegistry.superPositionBank())
            revert Error.NOT_SUPER_POSITION_BANK();
        _;
    }

    /// @dev constructor
    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev socket.tech fails without a native receive function.
    receive() external payable {}

    /// @inheritdoc ISuperRouter
    function multiDstMultiVaultDeposit(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable override {
        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            singleDstMultiVaultDeposit(
                SingleDstMultiVaultsStateReq(
                    req.ambIds,
                    req.dstChainIds[i],
                    req.superFormsData[i],
                    req.extraDataPerDst[i]
                )
            );
        }
    }

    /// @inheritdoc ISuperRouter
    function singleDstMultiVaultDeposit(
        SingleDstMultiVaultsStateReq memory req
    ) public payable override {
        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;
        vars.srcSender = msg.sender;

        vars.srcChainId = superRegistry.chainId();
        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData
        if (!_validateSuperFormsDepositData(req.superFormsData))
            revert Error.INVALID_SUPERFORMS_DATA();

        totalTransactions++;
        vars.currentTotalTransactions = totalTransactions;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            _packTxData(
                vars.srcSender,
                vars.srcChainId,
                vars.currentTotalTransactions
            ),
            req.superFormsData.superFormIds,
            req.superFormsData.amounts,
            req.superFormsData.maxSlippage,
            new LiqRequest[](0),
            req.superFormsData.extraFormData
        );

        /// @dev same chain action
        if (vars.srcChainId == vars.dstChainId) {
            _directMultiDeposit(
                vars.srcSender,
                req.superFormsData.liqRequests,
                ambData
            );
            emit Completed(vars.currentTotalTransactions);
        } else {
            address permit2 = superRegistry.PERMIT2();
            address superForm;
            /// @dev this loop is what allows to deposit to >1 different underlying on destination
            /// @dev if a loop fails in a validation the whole chain should be reverted
            for (
                uint256 j = 0;
                j < req.superFormsData.liqRequests.length;
                j++
            ) {
                vars.liqRequest = req.superFormsData.liqRequests[j];
                /// @dev dispatch liquidity data
                (superForm, , ) = _getSuperForm(
                    req.superFormsData.superFormIds[j]
                );

                _validateAndDispatchTokens(
                    vars.liqRequest,
                    permit2,
                    superForm,
                    vars.srcChainId,
                    vars.dstChainId,
                    vars.srcSender,
                    true
                );
            }

            _dispatchAmbMessage(
                TransactionType.DEPOSIT,
                abi.encode(ambData),
                true,
                req.extraData,
                req.ambIds,
                vars.dstChainId,
                vars.currentTotalTransactions
            );

            emit CrossChainInitiated(vars.currentTotalTransactions);
        }
    }

    /// @inheritdoc ISuperRouter
    function multiDstSingleVaultDeposit(
        MultiDstSingleVaultStateReq calldata req
    ) external payable override {
        uint16 dstChainId;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            dstChainId = req.dstChainIds[i];
            if (superRegistry.chainId() == dstChainId) {
                singleDirectSingleVaultDeposit(
                    SingleDirectSingleVaultStateReq(
                        dstChainId,
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            } else {
                singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(
                        req.ambIds,
                        dstChainId,
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            }
        }
    }

    function singleXChainSingleVaultDeposit(
        SingleXChainSingleVaultStateReq memory req
    ) public payable override {
        ActionLocalVars memory vars;

        vars.srcSender = msg.sender;

        vars.srcChainId = superRegistry.chainId();
        vars.dstChainId = req.dstChainId;

        if (vars.srcChainId == vars.dstChainId)
            revert Error.INVALID_CHAIN_IDS();

        InitSingleVaultData memory ambData;
        (ambData, vars.currentTotalTransactions) = _buildDepositAmbData(
            vars.srcSender,
            vars.srcChainId,
            vars.dstChainId,
            req.superFormData
        );

        vars.liqRequest = req.superFormData.liqRequest;

        (address superForm, , ) = _getSuperForm(req.superFormData.superFormId);

        _validateAndDispatchTokens(
            vars.liqRequest,
            superRegistry.PERMIT2(),
            superForm,
            vars.srcChainId,
            vars.dstChainId,
            vars.srcSender,
            true
        );

        _dispatchAmbMessage(
            TransactionType.DEPOSIT,
            abi.encode(ambData),
            false,
            req.extraData,
            req.ambIds,
            vars.dstChainId,
            vars.currentTotalTransactions
        );

        emit CrossChainInitiated(vars.currentTotalTransactions);
    }

    function singleDirectSingleVaultDeposit(
        SingleDirectSingleVaultStateReq memory req
    ) public payable override {
        ActionLocalVars memory vars;

        vars.srcSender = msg.sender;

        vars.srcChainId = superRegistry.chainId();
        vars.dstChainId = req.dstChainId;

        if (vars.srcChainId != vars.dstChainId)
            revert Error.INVALID_CHAIN_IDS();

        InitSingleVaultData memory ambData;
        (ambData, vars.currentTotalTransactions) = _buildDepositAmbData(
            vars.srcSender,
            vars.srcChainId,
            vars.dstChainId,
            req.superFormData
        );

        /// @dev same chain action

        _directSingleDeposit(
            vars.srcSender,
            req.superFormData.liqRequest,
            ambData
        );

        emit Completed(vars.currentTotalTransactions);
    }

    /// @inheritdoc ISuperRouter
    function multiDstMultiVaultWithdraw(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable override {
        uint256 nDestinations = req.dstChainIds.length;

        for (uint256 i = 0; i < nDestinations; i++) {
            singleDstMultiVaultWithdraw(
                SingleDstMultiVaultsStateReq(
                    req.ambIds,
                    req.dstChainIds[i],
                    req.superFormsData[i],
                    req.extraDataPerDst[i]
                )
            );
        }
    }

    /// @inheritdoc ISuperRouter
    function singleDstMultiVaultWithdraw(
        SingleDstMultiVaultsStateReq memory req
    ) public payable override {
        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;
        vars.srcSender = msg.sender;

        vars.srcChainId = superRegistry.chainId();
        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData
        if (!_validateSuperFormsWithdrawData(req.superFormsData))
            revert Error.INVALID_SUPERFORMS_DATA();

        ISuperPositions(superRegistry.superPositions()).burnBatchSP(
            vars.srcSender,
            req.superFormsData.superFormIds,
            req.superFormsData.amounts
        );

        totalTransactions++;
        vars.currentTotalTransactions = totalTransactions;

        /// @dev write packed txData
        ambData = InitMultiVaultData(
            _packTxData(
                vars.srcSender,
                vars.srcChainId,
                vars.currentTotalTransactions
            ),
            req.superFormsData.superFormIds,
            req.superFormsData.amounts,
            req.superFormsData.maxSlippage,
            req.superFormsData.liqRequests,
            req.superFormsData.extraFormData
        );

        /// @dev same chain action
        if (vars.srcChainId == vars.dstChainId) {
            _directMultiWithdraw(req.superFormsData.liqRequests, ambData);
            emit Completed(vars.currentTotalTransactions);
        } else {
            _dispatchAmbMessage(
                TransactionType.WITHDRAW,
                abi.encode(ambData),
                true,
                req.extraData,
                req.ambIds,
                vars.dstChainId,
                vars.currentTotalTransactions
            );

            emit CrossChainInitiated(vars.currentTotalTransactions);
        }
    }

    /// @inheritdoc ISuperRouter
    function multiDstSingleVaultWithdraw(
        MultiDstSingleVaultStateReq calldata req
    ) external payable override {
        uint16 dstChainId;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            dstChainId = req.dstChainIds[i];
            if (superRegistry.chainId() == dstChainId) {
                singleDirectSingleVaultWithdraw(
                    SingleDirectSingleVaultStateReq(
                        dstChainId,
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            } else {
                singleXChainSingleVaultWithdraw(
                    SingleXChainSingleVaultStateReq(
                        req.ambIds,
                        dstChainId,
                        req.superFormsData[i],
                        req.extraDataPerDst[i]
                    )
                );
            }
        }
    }

    /// @inheritdoc ISuperRouter
    function singleXChainSingleVaultWithdraw(
        SingleXChainSingleVaultStateReq memory req
    ) public payable override {
        ActionLocalVars memory vars;

        vars.srcSender = msg.sender;

        vars.srcChainId = superRegistry.chainId();
        vars.dstChainId = req.dstChainId;

        if (vars.srcChainId == vars.dstChainId)
            revert Error.INVALID_CHAIN_IDS();

        /// @dev validate superFormsData
        if (!_validateSuperFormData(vars.dstChainId, req.superFormData))
            revert Error.INVALID_SUPERFORMS_DATA();

        ISuperPositions(superRegistry.superPositions()).burnSingleSP(
            vars.srcSender,
            req.superFormData.superFormId,
            req.superFormData.amount
        );

        InitSingleVaultData memory ambData;

        (ambData, vars.currentTotalTransactions) = _buildWithdrawAmbData(
            vars.srcSender,
            vars.srcChainId,
            vars.dstChainId,
            req.superFormData
        );

        _dispatchAmbMessage(
            TransactionType.WITHDRAW,
            abi.encode(ambData),
            false,
            req.extraData,
            req.ambIds,
            vars.dstChainId,
            vars.currentTotalTransactions
        );

        emit CrossChainInitiated(vars.currentTotalTransactions);
    }

    /// @inheritdoc ISuperRouter
    function singleDirectSingleVaultWithdraw(
        SingleDirectSingleVaultStateReq memory req
    ) public payable override {
        ActionLocalVars memory vars;
        InitSingleVaultData memory ambData;

        vars.srcSender = msg.sender;

        vars.srcChainId = superRegistry.chainId();
        vars.dstChainId = req.dstChainId;

        if (vars.srcChainId != vars.dstChainId)
            revert Error.INVALID_CHAIN_IDS();

        /// @dev validate superFormsData
        if (!_validateSuperFormData(vars.dstChainId, req.superFormData))
            revert Error.INVALID_SUPERFORMS_DATA();

        /// @dev burn SuperPositions
        ISuperPositions(superRegistry.superPositions()).burnSingleSP(
            vars.srcSender,
            req.superFormData.superFormId,
            req.superFormData.amount
        );

        (ambData, vars.currentTotalTransactions) = _buildWithdrawAmbData(
            vars.srcSender,
            vars.srcChainId,
            vars.dstChainId,
            req.superFormData
        );

        /// @dev same chain action

        _directSingleWithdraw(req.superFormData.liqRequest, ambData);

        emit Completed(vars.currentTotalTransactions);
    }

    function _buildDepositAmbData(
        address srcSender_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        SingleVaultSFData memory superFormData_
    )
        internal
        returns (
            InitSingleVaultData memory ambData,
            uint80 currentTotalTransactions
        )
    {
        /// @dev validate superFormsData

        if (!_validateSuperFormData(dstChainId_, superFormData_))
            revert Error.INVALID_SUPERFORMS_DATA();

        if (
            !IBridgeValidator(
                superRegistry.getBridgeValidator(
                    superFormData_.liqRequest.bridgeId
                )
            ).validateTxDataAmount(
                    superFormData_.liqRequest.txData,
                    superFormData_.amount
                )
        ) revert Error.INVALID_TXDATA_AMOUNTS();

        totalTransactions++;
        currentTotalTransactions = totalTransactions;
        LiqRequest memory emptyRequest;

        ambData = InitSingleVaultData(
            _packTxData(srcSender_, srcChainId_, currentTotalTransactions),
            superFormData_.superFormId,
            superFormData_.amount,
            superFormData_.maxSlippage,
            emptyRequest,
            superFormData_.extraFormData
        );
    }

    function _buildWithdrawAmbData(
        address srcSender_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        SingleVaultSFData memory superFormData_
    )
        internal
        returns (
            InitSingleVaultData memory ambData,
            uint80 currentTotalTransactions
        )
    {
        totalTransactions++;
        currentTotalTransactions = totalTransactions;

        ambData = InitSingleVaultData(
            _packTxData(srcSender_, srcChainId_, currentTotalTransactions),
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
        uint16 srcChainId_,
        uint16 dstChainId_,
        address srcSender_,
        bool deposit_
    ) internal {
        IBridgeValidator(superRegistry.getBridgeValidator(liqRequest_.bridgeId))
            .validateTxData(
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

    function _dispatchAmbMessage(
        TransactionType txType_,
        bytes memory ambData_,
        bool multiVaults_,
        bytes memory extraData_,
        uint8[] memory ambIds_,
        uint16 dstChainId_,
        uint80 currentTotalTransactions_
    ) internal {
        AMBMessage memory ambMessage = AMBMessage(
            _packTxInfo(
                uint120(txType_),
                uint120(CallbackType.INIT),
                multiVaults_,
                STATE_REGISTRY_TYPE
            ),
            ambData_
        );
        SingleDstAMBParams memory ambParams = abi.decode(
            extraData_,
            (SingleDstAMBParams)
        );

        /// @dev _liqReq should have path encoded for withdraw to SuperRouter on chain different than chainId
        /// @dev construct txData in this fashion: from FTM SOURCE send message to BSC DESTINATION
        /// @dev so that BSC DISPATCHTOKENS sends tokens to AVAX receiver (EOA/contract/user-specified)
        /// @dev sync could be a problem, how long Socket path stays vaild vs. how fast we bridge/receive on Dst
        IBaseStateRegistry(superRegistry.coreStateRegistry()).dispatchPayload{
            value: ambParams.gasToPay
        }(
            ambIds_,
            dstChainId_,
            abi.encode(ambMessage),
            ambParams.encodedAMBExtraData
        );

        ISuperPositions(superRegistry.superPositions()).updateTxHistory(
            currentTotalTransactions_,
            ambMessage
        );
    }

    function _directDeposit(
        address superForm,
        uint256 txData_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_,
        uint256 msgValue_
    ) internal returns (uint256 dstAmount) {
        /// @dev deposits collateral to a given vault and mint vault positions.
        /// @dev FIXME: in multi deposits we split the msg.value, but this only works if we validate that the user is only depositing from one source asset (native in this case)
        dstAmount = IBaseForm(superForm).directDepositIntoVault{
            value: msgValue_
        }(
            InitSingleVaultData(
                txData_,
                superFormId_,
                amount_,
                maxSlippage_,
                liqData_,
                extraFormData_
            )
        );
    }

    /**
     * @notice deposit() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function _directSingleDeposit(
        address srcSender_,
        LiqRequest memory liqRequest_,
        InitSingleVaultData memory ambData_
    ) internal {
        address superForm;
        uint256 dstAmount;
        /// @dev decode superforms
        (superForm, , ) = _getSuperForm(ambData_.superFormId);

        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            superForm,
            ambData_.txData,
            ambData_.superFormId,
            ambData_.amount,
            ambData_.maxSlippage,
            liqRequest_,
            ambData_.extraFormData,
            msg.value
        );

        ISuperPositions(superRegistry.superPositions()).mintSingleSP(
            srcSender_,
            ambData_.superFormId,
            dstAmount
        );
    }

    /**
     * @notice deposit() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function _directMultiDeposit(
        address srcSender_,
        LiqRequest[] memory liqRequests_,
        InitMultiVaultData memory ambData_
    ) internal {
        uint256 len = ambData_.superFormIds.length;

        address[] memory superForms = new address[](len);

        uint256[] memory dstAmounts = new uint256[](len);
        /// @dev decode superforms
        (superForms, , ) = _getSuperForms(ambData_.superFormIds);

        for (uint256 i = 0; i < len; i++) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            dstAmounts[i] = _directDeposit(
                superForms[i],
                ambData_.txData,
                ambData_.superFormIds[i],
                ambData_.amounts[i],
                ambData_.maxSlippage[i],
                liqRequests_[i],
                ambData_.extraFormData,
                msg.value / len /// @dev FIXME: is this acceptable ? Note that the user fully controls the msg.value being sent
            );
        }

        /// @dev TEST-CASE: msg.sender to whom we mint. use passed `admin` arg?
        ISuperPositions(superRegistry.superPositions()).mintBatchSP(
            srcSender_,
            ambData_.superFormIds,
            dstAmounts
        );
    }

    function _directWithdraw(
        address superForm,
        uint256 txData_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        LiqRequest memory liqData_,
        bytes memory extraFormData_
    ) internal {
        /// @dev to allow bridging somewhere else requires arch change
        IBaseForm(superForm).directWithdrawFromVault(
            InitSingleVaultData(
                txData_,
                superFormId_,
                amount_,
                maxSlippage_,
                liqData_,
                extraFormData_
            )
        );
    }

    /**
     * @notice withdraw() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function _directSingleWithdraw(
        LiqRequest memory liqRequest_,
        InitSingleVaultData memory ambData_
    ) internal {
        /// @dev decode superforms
        (address superForm, , ) = _getSuperForm(ambData_.superFormId);

        _directWithdraw(
            superForm,
            ambData_.txData,
            ambData_.superFormId,
            ambData_.amount,
            ambData_.maxSlippage,
            liqRequest_,
            ambData_.extraFormData
        );
    }

    /**
     * @notice withdraw() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function _directMultiWithdraw(
        LiqRequest[] memory liqRequests_,
        InitMultiVaultData memory ambData_
    ) internal {
        /// @dev decode superforms
        (address[] memory superForms, , ) = _getSuperForms(
            ambData_.superFormIds
        );

        for (uint256 i = 0; i < superForms.length; i++) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            _directWithdraw(
                superForms[i],
                ambData_.txData,
                ambData_.superFormIds[i],
                ambData_.amounts[i],
                ambData_.maxSlippage[i],
                liqRequests_[i],
                ambData_.extraFormData
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                            DEV FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @notice should be removed after end-to-end testing.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    function withdrawToken(
        address _tokenContract,
        uint256 _amount
    ) external onlyProtocolAdmin {
        IERC20 tokenContract = IERC20(_tokenContract);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(superRegistry.protocolAdmin(), _amount);
    }

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function withdrawNativeToken(uint256 _amount) external onlyProtocolAdmin {
        payable(superRegistry.protocolAdmin()).transfer(_amount);
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _validateSuperFormData(
        uint16 dstChainId_,
        SingleVaultSFData memory superFormData_
    ) internal view returns (bool) {
        if (dstChainId_ != _getDestinationChain(superFormData_.superFormId))
            return false;

        if (superFormData_.maxSlippage > 10000) return false;

        (, uint256 formBeaconId_, ) = _getSuperForm(superFormData_.superFormId);

        if (
            IFormBeacon(
                ISuperFormFactory(superRegistry.superFormFactory())
                    .getFormBeacon(formBeaconId_)
            ).paused()
        ) return false;

        /// @dev TODO validate TxData to avoid exploits

        return true;
    }

    function _validateSuperFormsDepositData(
        MultiVaultsSFData memory superFormsData_
    ) internal view returns (bool) {
        uint256 len = superFormsData_.amounts.length;
        uint256 liqRequestsLen = superFormsData_.liqRequests.length;

        if (len == 0 || liqRequestsLen == 0) return false;

        /// @dev sizes validation

        if (
            !(superFormsData_.superFormIds.length ==
                superFormsData_.amounts.length &&
                superFormsData_.superFormIds.length ==
                superFormsData_.maxSlippage.length)
        ) {
            return false;
        }

        uint256 sumAmounts;

        (address firstSuperForm, , ) = _getSuperForm(
            superFormsData_.superFormIds[0]
        );
        address collateral = address(
            IBaseForm(firstSuperForm).getUnderlyingOfVault()
        );

        if (collateral == address(0)) return false;

        /// @dev slippage and paused validation
        for (uint256 i = 0; i < len; i++) {
            if (superFormsData_.maxSlippage[i] > 10000) return false;
            (, uint256 formBeaconId_, ) = _getSuperForm(
                superFormsData_.superFormIds[i]
            );

            if (
                IFormBeacon(
                    ISuperFormFactory(superRegistry.superFormFactory())
                        .getFormBeacon(formBeaconId_)
                ).paused()
            ) return false;

            sumAmounts += superFormsData_.amounts[i];

            /// @dev compare underlyings with the first superForm. If there is at least one different mark collateral as 0
            if (collateral != address(0) && i + 1 < len) {
                (address superForm, , ) = _getSuperForm(
                    superFormsData_.superFormIds[i + 1]
                );

                if (
                    collateral !=
                    address(IBaseForm(superForm).getUnderlyingOfVault())
                ) collateral = address(0);
            }
        }

        /// @dev In multiVaults, if there is only one liqRequest, then the sum of the amounts must be equal to the amount in the liqRequest and all underlyings must be equal
        if (
            liqRequestsLen == 1 &&
            (liqRequestsLen != len) &&
            (
                IBridgeValidator(
                    superRegistry.getBridgeValidator(
                        superFormsData_.liqRequests[0].bridgeId
                    )
                ).validateTxDataAmount(
                        superFormsData_.liqRequests[0].txData,
                        sumAmounts
                    )
            ) &&
            collateral == address(0)
        ) {
            return false;
        } else if (liqRequestsLen > 1 && collateral == address(0)) {
            /// @dev else if number of liq request >1, length must be equal to the number of superForms sent in this request (and all colaterals are different)

            if (liqRequestsLen != len) {
                return false;

                /// @dev else if number of liq request >1 and  length is equal to the number of superForms sent in this request, then all amounts in liqRequest must be equal to the amounts in superformsdata
            } else if (liqRequestsLen == len) {
                for (uint256 i = 0; i < liqRequestsLen; i++) {
                    IBridgeValidator(
                        superRegistry.getBridgeValidator(
                            superFormsData_.liqRequests[i].bridgeId
                        )
                    ).validateTxDataAmount(
                            superFormsData_.liqRequests[i].txData,
                            superFormsData_.amounts[i]
                        );
                }
            }
            /// @dev else if number of liq request >1 and all colaterals are the same, then this request should be invalid (?)
            /// @notice we could allow it but would imply multiple bridging of the same tokens
        } else if (liqRequestsLen > 1 && collateral != address(0)) {
            return false;
        }

        return true;
    }

    function _validateSuperFormsWithdrawData(
        MultiVaultsSFData memory superFormsData_
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
            !(superFormsData_.superFormIds.length ==
                superFormsData_.amounts.length &&
                superFormsData_.superFormIds.length ==
                superFormsData_.maxSlippage.length)
        ) {
            return false;
        }

        /// @dev slippage and paused validation
        for (uint256 i = 0; i < len; i++) {
            if (superFormsData_.maxSlippage[i] > 10000) return false;
            (, uint256 formBeaconId_, ) = _getSuperForm(
                superFormsData_.superFormIds[i]
            );
            if (
                IFormBeacon(
                    ISuperFormFactory(superRegistry.superFormFactory())
                        .getFormBeacon(formBeaconId_)
                ).paused()
            ) return false;
        }

        return true;
    }
}
