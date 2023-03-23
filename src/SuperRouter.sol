/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {LiqRequest, TransactionType, ReturnMultiData, ReturnSingleData, CallbackType, MultiVaultsSFData, SingleVaultSFData, MultiDstMultiVaultsStateReq, SingleDstMultiVaultsStateReq, MultiDstSingleVaultStateReq, SingleXChainSingleVaultStateReq, SingleDirectSingleVaultStateReq, InitMultiVaultData, InitSingleVaultData, AMBMessage} from "./types/DataTypes.sol";
import {IStateRegistry} from "./interfaces/IStateRegistry.sol";
import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";
import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperRouter} from "./interfaces/ISuperRouter.sol";
import "./crosschain-liquidity/LiquidityHandler.sol";
import "./utils/DataPacking.sol";

/// @title Super Router
/// @author Zeropoint Labs.
/// @dev Routes users funds and deposit information to a remote execution chain.
/// extends ERC1155 and Socket's Liquidity Handler.
contract SuperRouter is ISuperRouter, ERC1155, LiquidityHandler, Ownable {
    using SafeERC20 for IERC20;
    using Strings for string;

    /*///////////////////////////////////////////////////////////////
                                State Variables
    //////////////////////////////////////////////////////////////*/
    string public name = "SuperPositions";
    string public symbol = "SP";
    string public dynamicURI = "https://api.superform.xyz/superposition/";

    /// @notice state = information about destination chain & vault id.
    /// @notice  stateRegistry accepts requests from whitelisted addresses.
    /// @dev stateRegistry integrates with interblockchain messaging protocols.
    IStateRegistry public stateRegistry;

    /// @notice chainId represents unique chain id for each chains.
    /// @dev maybe should be constant or immutable
    uint16 public chainId;

    uint80 public totalTransactions;

    ISuperFormFactory public immutable superFormFactory;

    /// @notice history of state sent across chains are used for debugging.
    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint80 => AMBMessage) public txHistory;

    /// @notice bridge id is mapped to its execution address.
    /// @dev maps all the bridges to their address.
    mapping(uint8 => address) public bridgeAddress;

    /// @param chainId_              SuperForm chain id
    /// @param baseUri_              URL for external metadata of ERC1155 SuperPositions
    /// @param stateRegistry_         State registry address deployed
    /// @param superFormFactory_         SuperFormFactory address deployed
    constructor(
        uint16 chainId_,
        string memory baseUri_,
        IStateRegistry stateRegistry_,
        ISuperFormFactory superFormFactory_
    ) ERC1155(baseUri_) {
        if (chainId_ == 0) revert INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        stateRegistry = stateRegistry_;
        superFormFactory = superFormFactory_;
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev socket.tech fails without a native receive function.
    receive() external payable {}

    function multiDstMultiVaultDeposit(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable override {
        uint256 nDestinations = req.dstChainIds.length;
        for (uint256 i = 0; i < nDestinations; i++) {
            singleDstMultiVaultDeposit(
                SingleDstMultiVaultsStateReq(
                    req.primaryAmbId,
                    req.secondaryAmbIds,
                    req.dstChainIds[i],
                    req.superFormsData[i],
                    req.adapterParam,
                    req.msgValue / nDestinations /// @dev FIXME: check if there is a better way to send msgValue to avoid issues
                )
            );
        }
    }

    function singleDstMultiVaultDeposit(
        SingleDstMultiVaultsStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;
        vars.srcSender = _msgSender();

        vars.srcChainId = chainId;
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData

        if (!_validateSuperFormsData(vars.dstChainId, req.superFormsData))
            revert INVALID_SUPERFORMS_DATA();

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
            req.superFormsData.extraFormData,
            ""
        );

        /// @dev write amb message
        vars.ambMessage = AMBMessage(
            _packTxInfo(
                uint120(TransactionType.DEPOSIT),
                uint120(CallbackType.INIT),
                true
            ),
            abi.encode(ambData)
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
            vars.liqRequestsLen = req.superFormsData.liqRequests.length;

            /// @dev this loop is what allows to deposit to >1 different underlying on destination
            /// @dev if a loop fails in a validation the whole chain should be reverted
            for (uint256 j = 0; j < vars.liqRequestsLen; j++) {
                vars.liqRequest = req.superFormsData.liqRequests[j];
                /// @dev dispatch liquidity data
                dispatchTokens(
                    bridgeAddress[vars.liqRequest.bridgeId],
                    vars.liqRequest.txData,
                    vars.liqRequest.token,
                    vars.liqRequest.allowanceTarget, /// to be removed
                    vars.liqRequest.amount,
                    vars.srcSender,
                    vars.liqRequest.nativeAmount
                );
            }

            stateRegistry.dispatchPayload{value: req.msgValue}(
                req.primaryAmbId, ///  @dev <- misses a second argument to send secondary amb ids - WIP sujith
                vars.dstChainId,
                abi.encode(vars.ambMessage),
                req.adapterParam
            );

            txHistory[vars.currentTotalTransactions] = vars.ambMessage;

            emit CrossChainInitiated(vars.currentTotalTransactions);
        }
    }

    function multiDstSingleVaultDeposit(
        MultiDstSingleVaultStateReq calldata req
    ) external payable {
        uint16 dstChainId;
        uint256 nDestinations = req.dstChainIds.length;

        for (uint256 i = 0; i < nDestinations; i++) {
            dstChainId = req.dstChainIds[i];
            if (chainId == dstChainId) {
                singleDirectSingleVaultDeposit(
                    SingleDirectSingleVaultStateReq(
                        dstChainId,
                        req.superFormsData[i],
                        req.adapterParam,
                        req.msgValue / nDestinations /// @dev FIXME: check if there is a better way to send msgValue to avoid issues
                    )
                );
            } else {
                singleXChainSingleVaultDeposit(
                    SingleXChainSingleVaultStateReq(
                        req.primaryAmbId,
                        req.secondaryAmbIds,
                        dstChainId,
                        req.superFormsData[i],
                        req.adapterParam,
                        req.msgValue / nDestinations /// @dev FIXME: check if there is a better way to send msgValue to avoid issues
                    )
                );
            }
        }
    }

    function singleXChainSingleVaultDeposit(
        SingleXChainSingleVaultStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;

        vars.srcSender = _msgSender();

        vars.srcChainId = chainId;
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        if (vars.srcChainId == vars.dstChainId) revert INVALID_CHAIN_IDS();

        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData

        if (!_validateSuperFormData(vars.dstChainId, req.superFormData))
            revert INVALID_SUPERFORMS_DATA();

        totalTransactions++;
        vars.currentTotalTransactions = totalTransactions;

        /// @dev write amb message
        vars.ambMessage = AMBMessage(
            _packTxInfo(
                uint120(TransactionType.DEPOSIT),
                uint120(CallbackType.INIT),
                false
            ),
            abi.encode(
                InitSingleVaultData(
                    _packTxData(
                        vars.srcSender,
                        vars.srcChainId,
                        vars.currentTotalTransactions
                    ),
                    req.superFormData.superFormId,
                    req.superFormData.amount,
                    req.superFormData.maxSlippage,
                    req.superFormData.extraFormData,
                    ""
                )
            )
        );

        vars.liqRequest = req.superFormData.liqRequest;
        /// @dev dispatch liquidity data
        dispatchTokens(
            bridgeAddress[vars.liqRequest.bridgeId],
            vars.liqRequest.txData,
            vars.liqRequest.token,
            vars.liqRequest.allowanceTarget, /// to be removed
            vars.liqRequest.amount,
            vars.srcSender,
            vars.liqRequest.nativeAmount
        );

        stateRegistry.dispatchPayload{value: req.msgValue}(
            req.primaryAmbId, ///  @dev <- misses a second argument to send secondary amb ids - WIP sujith
            vars.dstChainId,
            abi.encode(vars.ambMessage),
            req.adapterParam
        );
        txHistory[vars.currentTotalTransactions] = vars.ambMessage;

        emit CrossChainInitiated(vars.currentTotalTransactions);
    }

    function singleDirectSingleVaultDeposit(
        SingleDirectSingleVaultStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;
        InitSingleVaultData memory ambData;

        vars.srcSender = _msgSender();

        vars.srcChainId = chainId;
        if (vars.srcChainId != vars.dstChainId) revert INVALID_CHAIN_IDS();

        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData

        if (!_validateSuperFormData(vars.dstChainId, req.superFormData))
            revert INVALID_SUPERFORMS_DATA();

        totalTransactions++;
        vars.currentTotalTransactions = totalTransactions;

        ambData = InitSingleVaultData(
            _packTxData(
                vars.srcSender,
                vars.srcChainId,
                vars.currentTotalTransactions
            ),
            req.superFormData.superFormId,
            req.superFormData.amount,
            req.superFormData.maxSlippage,
            req.superFormData.extraFormData,
            ""
        );

        /// @dev same chain action

        _directSingleDeposit(
            vars.srcSender,
            req.superFormData.liqRequest,
            ambData
        );

        emit Completed(vars.currentTotalTransactions);
    }

    function multiDstMultiVaultWithdraw(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable {
        uint256 nDestinations = req.dstChainIds.length;
        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            singleDstMultiVaultWithdraw(
                SingleDstMultiVaultsStateReq(
                    req.primaryAmbId,
                    req.secondaryAmbIds,
                    req.dstChainIds[i],
                    req.superFormsData[i],
                    req.adapterParam,
                    req.msgValue / nDestinations /// @dev FIXME: check if there is a better way to send msgValue to avoid issues
                )
            );
        }
    }

    function singleDstMultiVaultWithdraw(
        SingleDstMultiVaultsStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;
        InitMultiVaultData memory ambData;
        vars.srcSender = _msgSender();

        vars.srcChainId = chainId;
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData

        if (!_validateSuperFormsData(vars.dstChainId, req.superFormsData))
            revert INVALID_SUPERFORMS_DATA();

        /// @dev burn SuperPositions
        _burnBatch(
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
            req.superFormsData.extraFormData,
            abi.encode(req.superFormsData.liqRequests)
        );

        /// @dev write amb message
        vars.ambMessage = AMBMessage(
            _packTxInfo(
                uint120(TransactionType.WITHDRAW),
                uint120(CallbackType.INIT),
                true
            ),
            abi.encode(ambData)
        );

        /// @dev same chain action
        if (vars.srcChainId == vars.dstChainId) {
            _directMultiWithdraw(
                vars.srcSender,
                req.superFormsData.liqRequests,
                ambData
            );
            emit Completed(vars.currentTotalTransactions);
        } else {
            /// @dev _liqReq should have path encoded for withdraw to SuperRouter on chain different than chainId
            /// @dev construct txData in this fashion: from FTM SOURCE send message to BSC DESTINATION
            /// @dev so that BSC DISPATCHTOKENS sends tokens to AVAX receiver (EOA/contract/user-specified)
            /// @dev sync could be a problem, how long Socket path stays vaild vs. how fast we bridge/receive on Dst
            stateRegistry.dispatchPayload{value: req.msgValue}(
                req.primaryAmbId, ///  @dev <- misses a second argument to send secondary amb ids - WIP sujith
                vars.dstChainId,
                abi.encode(vars.ambMessage),
                req.adapterParam
            );
            txHistory[vars.currentTotalTransactions] = vars.ambMessage;

            emit CrossChainInitiated(vars.currentTotalTransactions);
        }
    }

    function multiDstSingleVaultWithdraw(
        MultiDstSingleVaultStateReq calldata req
    ) external payable {
        uint16 dstChainId;
        uint256 nDestinations = req.dstChainIds.length;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            dstChainId = req.dstChainIds[i];
            if (chainId == dstChainId) {
                singleDirectSingleVaultWithdraw(
                    SingleDirectSingleVaultStateReq(
                        dstChainId,
                        req.superFormsData[i],
                        req.adapterParam,
                        req.msgValue / nDestinations /// @dev FIXME: check if there is a better way to send msgValue to avoid issues
                    )
                );
            } else {
                singleXChainSingleVaultWithdraw(
                    SingleXChainSingleVaultStateReq(
                        req.primaryAmbId,
                        req.secondaryAmbIds,
                        dstChainId,
                        req.superFormsData[i],
                        req.adapterParam,
                        req.msgValue / nDestinations /// @dev FIXME: check if there is a better way to send msgValue to avoid issues
                    )
                );
            }
        }
    }

    function singleXChainSingleVaultWithdraw(
        SingleXChainSingleVaultStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;

        vars.srcSender = _msgSender();

        vars.srcChainId = chainId;
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        if (vars.srcChainId == vars.dstChainId) revert INVALID_CHAIN_IDS();

        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData

        if (!_validateSuperFormData(vars.dstChainId, req.superFormData))
            revert INVALID_SUPERFORMS_DATA();

        /// @dev burn SuperPositions
        _burn(
            vars.srcSender,
            req.superFormData.superFormId,
            req.superFormData.amount
        );

        totalTransactions++;
        vars.currentTotalTransactions = totalTransactions;

        /// @dev write amb message
        vars.ambMessage = AMBMessage(
            _packTxInfo(
                uint120(TransactionType.DEPOSIT),
                uint120(CallbackType.INIT),
                false
            ),
            abi.encode(
                InitSingleVaultData(
                    _packTxData(
                        vars.srcSender,
                        vars.srcChainId,
                        vars.currentTotalTransactions
                    ),
                    req.superFormData.superFormId,
                    req.superFormData.amount,
                    req.superFormData.maxSlippage,
                    req.superFormData.extraFormData,
                    abi.encode(req.superFormData.liqRequest)
                )
            )
        );

        stateRegistry.dispatchPayload{value: req.msgValue}(
            req.primaryAmbId, ///  @dev <- misses a second argument to send secondary amb ids - WIP sujith
            vars.dstChainId,
            abi.encode(vars.ambMessage),
            req.adapterParam
        );

        txHistory[vars.currentTotalTransactions] = vars.ambMessage;

        emit CrossChainInitiated(vars.currentTotalTransactions);
    }

    function singleDirectSingleVaultWithdraw(
        SingleDirectSingleVaultStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;
        InitSingleVaultData memory ambData;

        vars.srcSender = _msgSender();

        vars.srcChainId = chainId;
        if (vars.srcChainId != vars.dstChainId) revert INVALID_CHAIN_IDS();

        vars.dstChainId = req.dstChainId;

        /// @dev validate superFormsData

        if (!_validateSuperFormData(vars.dstChainId, req.superFormData))
            revert INVALID_SUPERFORMS_DATA();

        /// @dev burn SuperPositions
        _burn(
            vars.srcSender,
            req.superFormData.superFormId,
            req.superFormData.amount
        );

        totalTransactions++;
        vars.currentTotalTransactions = totalTransactions;

        ambData = InitSingleVaultData(
            _packTxData(
                vars.srcSender,
                vars.srcChainId,
                vars.currentTotalTransactions
            ),
            req.superFormData.superFormId,
            req.superFormData.amount,
            req.superFormData.maxSlippage,
            req.superFormData.extraFormData,
            abi.encode(req.superFormData.liqRequest)
        );

        /// @dev same chain action

        _directSingleWithdraw(
            vars.srcSender,
            req.superFormData.liqRequest,
            ambData
        );

        emit Completed(vars.currentTotalTransactions);
    }

    function _directDeposit(
        uint256 formId_,
        uint256 txData_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        bytes memory extraFormData_,
        bytes memory liqData_,
        uint256 msgValue_
    ) internal returns (uint256 dstAmount) {
        /// @dev deposits collateral to a given vault and mint vault positions.
        /// @dev FIXME: in multi deposits we split the msg.value, but this only works if we validate that the user is only depositing from one source asset (native in this case)
        dstAmount = IBaseForm(superFormFactory.getForm(formId_))
            .directDepositIntoVault{value: msgValue_}(
            InitSingleVaultData(
                txData_,
                superFormId_,
                amount_,
                maxSlippage_,
                extraFormData_,
                liqData_
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
        uint256 formId;
        uint256 dstAmount;
        /// @dev decode superforms
        (, formId, ) = _getSuperForm(ambData_.superFormId);

        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            formId,
            ambData_.txData,
            ambData_.superFormId,
            ambData_.amount,
            ambData_.maxSlippage,
            ambData_.extraFormData,
            abi.encode(liqRequest_),
            msg.value
        );

        /// @dev TEST-CASE: _msgSender() to whom we mint. use passed `admin` arg?
        _mint(srcSender_, ambData_.superFormId, dstAmount, "");
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

        uint256[] memory formIds = new uint256[](len);

        uint256[] memory dstAmounts = new uint256[](len);
        /// @dev decode superforms
        (, formIds, ) = _getSuperForms(ambData_.superFormIds);

        for (uint256 i = 0; i < len; i++) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            dstAmounts[i] = _directDeposit(
                formIds[i],
                ambData_.txData,
                ambData_.superFormIds[i],
                ambData_.amounts[i],
                ambData_.maxSlippage[i],
                ambData_.extraFormData,
                abi.encode(liqRequests_[i]),
                msg.value / len /// @dev FIXME: is this acceptable ? Note that the user fully controls the msg.value being sent
            );
        }

        /// @dev TEST-CASE: _msgSender() to whom we mint. use passed `admin` arg?
        _mintBatch(srcSender_, ambData_.superFormIds, dstAmounts, "");
    }

    function _directWithdraw(
        uint256 formId_,
        uint256 txData_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        bytes memory extraFormData_,
        bytes memory liqData_
    ) internal {
        /// @dev to allow bridging somewhere else requires arch change
        IBaseForm(superFormFactory.getForm(formId_)).directWithdrawFromVault(
            InitSingleVaultData(
                txData_,
                superFormId_,
                amount_,
                maxSlippage_,
                extraFormData_,
                liqData_
            )
        );
    }

    /**
     * @notice withdraw() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function _directSingleWithdraw(
        address srcSender_,
        LiqRequest memory liqRequest_,
        InitSingleVaultData memory ambData_
    ) internal {
        /// @dev decode superforms
        (, uint256 formId, ) = _getSuperForm(ambData_.superFormId);

        _directWithdraw(
            formId,
            ambData_.txData,
            ambData_.superFormId,
            ambData_.amount,
            ambData_.maxSlippage,
            ambData_.extraFormData,
            abi.encode(liqRequest_)
        );
    }

    /**
     * @notice withdraw() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function _directMultiWithdraw(
        address srcSender_,
        LiqRequest[] memory liqRequests_,
        InitMultiVaultData memory ambData_
    ) internal {
        /// @dev decode superforms
        (, uint256[] memory formIds, ) = _getSuperForms(ambData_.superFormIds);

        for (uint256 i = 0; i < formIds.length; i++) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            _directWithdraw(
                formIds[i],
                ambData_.txData,
                ambData_.superFormIds[i],
                ambData_.amounts[i],
                ambData_.maxSlippage[i],
                ambData_.extraFormData,
                abi.encode(liqRequests_[i])
            );
        }
    }

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev allows admin to set the bridge address for an bridge id.
    /// @param bridgeId_         represents the bridge unqiue identifier.
    /// @param bridgeAddress_    represents the bridge address.
    function setBridgeAddress(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_
    ) external override onlyOwner {
        for (uint256 i = 0; i < bridgeId_.length; i++) {
            address x = bridgeAddress_[i];
            uint8 y = bridgeId_[i];
            if (x == address(0)) revert ZERO_BRIDGE_ADDRESS();

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    function stateMultiSync(AMBMessage memory data_) external payable override {
        if (msg.sender != address(stateRegistry)) revert REQUEST_DENIED();

        (uint256 txType, uint256 callbackType, ) = _decodeTxInfo(data_.txInfo);

        if (callbackType != uint256(CallbackType.RETURN))
            revert INVALID_PAYLOAD();

        ReturnMultiData memory returnData = abi.decode(
            data_.params,
            (ReturnMultiData)
        );

        (, , , uint80 returnTxId) = _decodeReturnTxInfo(
            returnData.returnTxInfo
        );
        AMBMessage memory stored = txHistory[returnTxId];

        (, , bool multi) = _decodeTxInfo(stored.txInfo);

        if (!multi) revert INVALID_PAYLOAD();

        (
            bool status,
            uint16 returnDataSrcChainId,
            uint16 returnDataDstChainId,
            uint80 returnDataTxId
        ) = _decodeReturnTxInfo(returnData.returnTxInfo);

        InitMultiVaultData memory multiVaultData = abi.decode(
            stored.params,
            (InitMultiVaultData)
        );
        (address srcSender, uint16 srcChainId, ) = _decodeTxData(
            multiVaultData.txData
        );

        if (returnDataSrcChainId != srcChainId) revert SRC_CHAIN_IDS_MISMATCH();

        if (
            returnDataDstChainId !=
            _getDestinationChain(multiVaultData.superFormIds[0])
        ) revert DST_CHAIN_IDS_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT) && status) {
            _mintBatch(
                srcSender,
                multiVaultData.superFormIds,
                returnData.amounts,
                ""
            );
        } else if (txType == uint256(TransactionType.WITHDRAW) && !status) {
            _mintBatch(
                srcSender,
                multiVaultData.superFormIds,
                returnData.amounts,
                ""
            );
        } else {
            revert INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnDataTxId);
    }

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param data_ is the received information to be processed.
    function stateSync(AMBMessage memory data_) external payable override {
        if (msg.sender != address(stateRegistry)) revert REQUEST_DENIED();

        (uint256 txType, uint256 callbackType, ) = _decodeTxInfo(data_.txInfo);

        if (callbackType != uint256(CallbackType.RETURN))
            revert INVALID_PAYLOAD();

        ReturnSingleData memory returnData = abi.decode(
            data_.params,
            (ReturnSingleData)
        );

        (, , , uint80 returnTxId) = _decodeReturnTxInfo(
            returnData.returnTxInfo
        );
        AMBMessage memory stored = txHistory[returnTxId];
        (, , bool multi) = _decodeTxInfo(stored.txInfo);

        if (multi) revert INVALID_PAYLOAD();

        (
            bool status,
            uint16 returnDataSrcChainId,
            uint16 returnDataDstChainId,
            uint80 returnDataTxId
        ) = _decodeReturnTxInfo(returnData.returnTxInfo);

        InitSingleVaultData memory singleVaultData = abi.decode(
            stored.params,
            (InitSingleVaultData)
        );
        (address srcSender, uint16 srcChainId, ) = _decodeTxData(
            singleVaultData.txData
        );

        if (returnDataSrcChainId != srcChainId) revert SRC_CHAIN_IDS_MISMATCH();

        if (
            returnDataDstChainId !=
            _getDestinationChain(singleVaultData.superFormId)
        ) revert DST_CHAIN_IDS_MISMATCH();

        if (txType == uint256(TransactionType.DEPOSIT) && status) {
            _mint(
                srcSender,
                singleVaultData.superFormId,
                returnData.amount,
                ""
            );
        } else if (txType == uint256(TransactionType.WITHDRAW) && !status) {
            /// @dev FIXME: need to create returnData MULTI AMOUNTS and update this to _mint
            _mint(
                srcSender,
                singleVaultData.superFormId,
                returnData.amount,
                ""
            );
        } else {
            revert INVALID_PAYLOAD_STATUS();
        }

        emit Completed(returnDataTxId);
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
    ) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(owner(), _amount);
    }

    /// @dev PREVILEGED admin ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    function withdrawNativeToken(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    /*///////////////////////////////////////////////////////////////
                            Read Only Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev returns the off-chain metadata URI for each ERC1155 super position.
    /// @param id_ is the unique identifier of the ERC1155 super position aka the vault id.
    /// @return string pointing to the off-chain metadata of the 1155 super position.
    function tokenURI(
        uint256 id_
    ) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(dynamicURI, Strings.toString(id_), ".json")
            );
    }

    /*///////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev for the separation of multi/single sp minting
    function _multiSuperPositionMint(
        AMBMessage memory stored,
        ReturnMultiData memory returnData,
        uint16 returnDataSrcChainId,
        uint16 returnDataDstChainId,
        uint256 txType,
        bool status
    ) internal {}

    /// @dev for the separation of multi/single sp minting
    function _singleSuperPositionMint(
        AMBMessage memory stored,
        ReturnSingleData memory returnData,
        uint16 returnDataSrcChainId,
        uint16 returnDataDstChainId,
        uint256 txType,
        bool status
    ) internal {}

    /// @dev validates slippage parameter;
    /// slippages should always be within 0 - 100
    /// decimal is handles in the form of 10s
    /// for eg. 0.05 = 5
    ///       100 = 10000
    function _validateSlippage(
        uint256[] calldata slippages_
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < slippages_.length; i++) {
            if (slippages_[i] < 0 || slippages_[i] > 10000) {
                return false;
            }
        }
        return true;
    }

    function _validateAmbs(
        uint8 primaryAmbId,
        uint8[] memory secondaryAmbIds
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < secondaryAmbIds.length; i++) {
            if (primaryAmbId == secondaryAmbIds[i]) {
                return false;
            }
        }
        return true;
    }

    function _validateSuperFormData(
        uint16 dstChainId_,
        SingleVaultSFData memory superFormData_
    ) internal view returns (bool) {
        if (dstChainId_ != _getDestinationChain(superFormData_.superFormId))
            return false;

        if (superFormData_.maxSlippage > 10000) return false;

        /// @dev TODO validate TxData to avoid exploits

        return true;
    }

    function _validateSuperFormsData(
        uint16 dstChainId_,
        MultiVaultsSFData memory superFormsData_
    ) internal pure returns (bool) {
        uint256 len = superFormsData_.amounts.length;
        uint256 liqRequestsLen = superFormsData_.liqRequests.length;
        uint256 sumAmounts;
        /// @dev size validation
        if (
            !(superFormsData_.superFormIds.length ==
                superFormsData_.amounts.length &&
                superFormsData_.superFormIds.length ==
                superFormsData_.maxSlippage.length)
        ) {
            return false;
        }

        for (uint256 i = 0; i < len; i++) {
            if (superFormsData_.maxSlippage[i] > 10000) return false;

            sumAmounts += superFormsData_.amounts[i];

            /// @dev TODO validate token correspond to superForms' underlying?
            /// @dev TODO validate TxData to avoid exploits
        }

        /// @dev In multiVaults, if there is only one liqRequest, then the sum of the amounts must be equal to the amount in the liqRequest
        if (
            liqRequestsLen == 1 &&
            (liqRequestsLen != len) &&
            superFormsData_.liqRequests[0].amount != sumAmounts
        ) {
            return false;
            /// @dev else if number of liq request >1, length must be equal to the number of superForms sent in this request
        } else if (liqRequestsLen > 1) {
            if (liqRequestsLen != len) {
                return false;
            }
        }

        return true;
    }
}
