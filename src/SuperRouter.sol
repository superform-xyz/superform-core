/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {StateReq, StateData, TransactionType, ReturnData, CallbackType, FormData, FormCommonData, FormXChainData} from "./types/DataTypes.sol";

import {MultiVaultsSFData, SingleVaultSFData, MultiDstMultiVaultsStateReq, SingleDstMultiVaultsStateReq, MultiDstSingleVaultStateReq, SingleXChainSingleVaultStateReq, SingleDirectSingleVaultStateReq, AMBInitMultiVaultData, AMBInitSingleVaultData, DirectActionData, AMBMessage} from "./types/NewDataTypes.sol";

import {IStateRegistry} from "./interfaces/IStateRegistry.sol";

import {ISuperFormFactory} from "./interfaces/ISuperFormFactory.sol";

import {IBaseForm} from "./interfaces/IBaseForm.sol";
import {ISuperRouter} from "./interfaces/ISuperRouter.sol";
import "./crosschain-liquidity/LiquidityHandler.sol";

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
    uint80 public chainId;

    /// @dev totalTransactions keeps track of overall routed transactions.
    uint256 public totalTransactions;

    uint80 public totalTxs;

    ISuperFormFactory public immutable superFormFactory;

    /// @notice history of state sent across chains are used for debugging.
    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 => StateData) public txHistory;

    /// @notice history of state sent across chains are used for debugging.
    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint80 => AMBMessage) public ambMessagesHistory;

    /// @notice bridge id is mapped to its execution address.
    /// @dev maps all the bridges to their address.
    mapping(uint8 => address) public bridgeAddress;

    /// @param chainId_              SuperForm chain id
    /// @param baseUri_              URL for external metadata of ERC1155 SuperPositions
    /// @param stateRegistry_         State registry address deployed
    /// @param superFormFactory_         SuperFormFactory address deployed
    constructor(
        uint80 chainId_,
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

    event InitiatedNew(uint80 indexed txId);
    error INVALID_AMB_IDS();
    error INVALID_SUPERFORMS_DATA();
    error INVALID_CHAIN_IDS();

    struct ActionLocalVars {
        AMBMessage ambMessage;
        LiqRequest liqRequest;
        uint16 srcChainId;
        uint16 dstChainId;
        uint80 currentTotalTransactions;
        address srcSender;
        uint256 liqRequestsLen;
    }

    /// @dev TO DELETE
    function deposit(
        LiqRequest[] calldata liqData_,
        StateReq[] calldata stateData_
    ) external payable {}

    /// @dev TO DELETE
    function withdraw(
        LiqRequest[] calldata liqData_, /// @dev Allow [] because user can request multiple tokens (as long as bridge has them - Needs check!)
        StateReq[] calldata stateData_
    ) external payable {}

    function multiDstMultiVaultDeposit(
        MultiDstMultiVaultsStateReq calldata req
    ) external payable {
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            singleDstMultiVaultDeposit(
                SingleDstMultiVaultsStateReq(
                    req.primaryAmbId,
                    req.secondaryAmbIds,
                    req.dstChainIds[i],
                    req.superFormsData[i],
                    req.adapterParam,
                    req.msgValue
                )
            );
        }
    }

    function singleDstMultiVaultDeposit(
        SingleDstMultiVaultsStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;
        AMBInitMultiVaultData memory ambData;
        vars.srcSender = _msgSender();

        /// @dev FIXME
        vars.srcChainId = uint16(chainId);
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        vars.dstChainId = req.dstChainId;
        totalTxs++;
        vars.currentTotalTransactions = totalTxs;

        /// @dev validate superFormsData

        if (!_validateSuperFormsData(vars.dstChainId, req.superFormsData))
            revert INVALID_SUPERFORMS_DATA();

        /// @dev write packed txData

        ambData = AMBInitMultiVaultData(
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
                uint128(TransactionType.DEPOSIT),
                uint128(CallbackType.INIT)
            ),
            abi.encode(ambData)
        );

        /// @dev same chain action
        /// @dev FIXME chainId should be 16 bits
        if (uint16(vars.srcChainId) == vars.dstChainId) {
            _directMultiDeposit(
                vars.srcSender,
                req.superFormsData.liqRequests,
                ambData
            );
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

            ambMessagesHistory[vars.currentTotalTransactions] = vars.ambMessage;
        }
        emit InitiatedNew(vars.currentTotalTransactions);
    }

    function multiDstSingleVaultDeposit(
        MultiDstSingleVaultStateReq calldata req
    ) external payable {
        uint16 srcChainId = uint16(chainId);
        uint16 dstChainId;

        for (uint256 i = 0; i < req.dstChainIds.length; i++) {
            dstChainId = req.dstChainIds[i];
            if (srcChainId == dstChainId) {
                singleDirectSingleVaultDeposit(
                    SingleDirectSingleVaultStateReq(
                        dstChainId,
                        req.superFormsData[i],
                        req.adapterParam,
                        req.msgValue
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
                        req.msgValue
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
        /// @dev FIXME
        vars.srcChainId = uint16(chainId);
        if (!_validateAmbs(req.primaryAmbId, req.secondaryAmbIds))
            revert INVALID_AMB_IDS();

        if (uint16(vars.srcChainId) == vars.dstChainId)
            revert INVALID_CHAIN_IDS();

        vars.dstChainId = req.dstChainId;
        totalTxs++;
        vars.currentTotalTransactions = totalTxs;

        /// @dev validate superFormsData

        if (!_validateSuperFormData(vars.dstChainId, req.superFormsData))
            revert INVALID_SUPERFORMS_DATA();

        /// @dev write amb message
        vars.ambMessage = AMBMessage(
            _packTxInfo(
                uint128(TransactionType.DEPOSIT),
                uint128(CallbackType.INIT)
            ),
            abi.encode(
                AMBInitSingleVaultData(
                    _packTxData(
                        vars.srcSender,
                        vars.srcChainId,
                        vars.currentTotalTransactions
                    ),
                    req.superFormsData.superFormId,
                    req.superFormsData.amount,
                    req.superFormsData.maxSlippage,
                    req.superFormsData.extraFormData,
                    ""
                )
            )
        );

        vars.liqRequest = req.superFormsData.liqRequest;
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

        ambMessagesHistory[vars.currentTotalTransactions] = vars.ambMessage;

        emit InitiatedNew(vars.currentTotalTransactions);
    }

    function singleDirectSingleVaultDeposit(
        SingleDirectSingleVaultStateReq memory req
    ) public payable {
        ActionLocalVars memory vars;
        AMBInitSingleVaultData memory ambData;

        vars.srcSender = _msgSender();
        /// @dev FIXME
        vars.srcChainId = uint16(chainId);
        if (uint16(vars.srcChainId) != vars.dstChainId)
            revert INVALID_CHAIN_IDS();

        vars.dstChainId = req.dstChainId;
        totalTxs++;
        vars.currentTotalTransactions = totalTxs;

        /// @dev validate superFormsData

        if (!_validateSuperFormData(vars.dstChainId, req.superFormsData))
            revert INVALID_SUPERFORMS_DATA();

        ambData = AMBInitSingleVaultData(
            _packTxData(
                vars.srcSender,
                vars.srcChainId,
                vars.currentTotalTransactions
            ),
            req.superFormsData.superFormId,
            req.superFormsData.amount,
            req.superFormsData.maxSlippage,
            req.superFormsData.extraFormData,
            ""
        );

        /// @dev same chain action

        _directSingleDeposit(
            vars.srcSender,
            req.superFormsData.liqRequest,
            ambData
        );

        emit InitiatedNew(vars.currentTotalTransactions);
    }

    function _directDeposit(
        uint256 formId_,
        uint256 txData_,
        uint256 superFormId_,
        uint256 amount_,
        uint256 maxSlippage_,
        bytes memory extraFormData_,
        bytes memory liqData_
    ) internal returns (uint256 dstAmount) {
        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = IBaseForm(superFormFactory.getForm(formId_))
            .directSingleDepositIntoVault{value: msg.value}(
            abi.encode(
                DirectActionData(
                    txData_,
                    superFormId_,
                    amount_,
                    maxSlippage_,
                    extraFormData_,
                    liqData_
                )
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
        AMBInitSingleVaultData memory ambData_
    ) internal {
        uint256 formId;
        uint256 dstAmount;
        /// @dev decode superforms
        /// @dev FIXME Assumes all forms have the same form id
        (, formId, ) = superFormFactory.getSuperForm(ambData_.superFormId);

        /// @dev deposits collateral to a given vault and mint vault positions.
        dstAmount = _directDeposit(
            formId,
            ambData_.txData,
            ambData_.superFormId,
            ambData_.amount,
            ambData_.maxSlippage,
            ambData_.extraFormData,
            abi.encode(liqRequest_)
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
        AMBInitMultiVaultData memory ambData_
    ) internal {
        uint256[] memory formIds = new uint256[](ambData_.superFormIds.length);
        uint256[] memory dstAmounts = new uint256[](
            ambData_.superFormIds.length
        );
        /// @dev decode superforms
        /// @dev FIXME Assumes all forms have the same form id
        (, formIds, ) = superFormFactory.getSuperForms(ambData_.superFormIds);

        for (uint256 i = 0; i < formIds.length; i++) {
            /// @dev deposits collateral to a given vault and mint vault positions.
            dstAmounts[i] = _directDeposit(
                formIds[i],
                ambData_.txData,
                ambData_.superFormIds[i],
                ambData_.amounts[i],
                ambData_.maxSlippage[i],
                ambData_.extraFormData,
                abi.encode(liqRequests_[i])
            );
        }

        /// @dev TEST-CASE: _msgSender() to whom we mint. use passed `admin` arg?
        _mintBatch(srcSender_, ambData_.superFormIds, dstAmounts, "");
    }

    /// @notice validates input and initiates withdrawal process
    function singleDirectWithdraw(
        LiqRequest calldata liqData_,
        StateReq calldata stateData_
    ) public payable override {
        if (stateData_.dstChainId != chainId) revert INVALID_INPUT_CHAIN_ID();

        address srcSender = _msgSender();

        _burnBatch(srcSender, stateData_.superFormIds, stateData_.amounts);

        totalTransactions++;
        /// @dev loading into memory here to save gas
        uint256 currentTotalTransactions = totalTransactions;

        FormCommonData memory formCommonData = FormCommonData(
            srcSender,
            stateData_.superFormIds,
            stateData_.amounts,
            abi.encode(liqData_)
        );

        FormData memory formData = FormData(
            chainId,
            stateData_.dstChainId,
            abi.encode(formCommonData),
            bytes(""),
            stateData_.extraFormData
        );

        bytes memory formDataEncoded = abi.encode(formData);

        /// @dev FIXME: doesn't seem relevant to store this info in txHistory for direct actions. Delete?
        StateData memory info = StateData(
            TransactionType.WITHDRAW,
            CallbackType.INIT,
            formDataEncoded
        );

        txHistory[currentTotalTransactions] = info;

        /// @dev decode superforms
        (, uint256[] memory formIds_, ) = superFormFactory.getSuperForms(
            stateData_.superFormIds
        );

        /// @dev FIXME only one form id is being used here!
        /// @dev to allow bridging somewhere else requires arch change
        IBaseForm(superFormFactory.getForm(formIds_[0]))
            .directWithdrawFromVault{value: msg.value}(formDataEncoded);

        /// @dev doesn't seem relevant to emit these two events for direct actions. Delete?
        emit Completed(currentTotalTransactions);

        emit Initiated(
            currentTotalTransactions,
            liqData_.token,
            liqData_.amount
        );
    }

    /// @notice validates input and initiates withdrawal process
    function singleXChainWithdraw(
        LiqRequest calldata liqData_,
        StateReq calldata stateData_
    ) public payable override {
        if (stateData_.dstChainId == chainId) revert INVALID_INPUT_CHAIN_ID();

        address srcSender = _msgSender();

        _burnBatch(srcSender, stateData_.superFormIds, stateData_.amounts);

        totalTransactions++;
        /// @dev loading into memory here to save gas
        uint256 currentTotalTransactions = totalTransactions;

        FormCommonData memory formCommonData = FormCommonData(
            srcSender,
            stateData_.superFormIds,
            stateData_.amounts,
            abi.encode(liqData_)
        );

        FormXChainData memory formXChainData = FormXChainData(
            currentTotalTransactions,
            stateData_.maxSlippage // not relevant for withdrawals
        );

        FormData memory formData = FormData(
            chainId,
            stateData_.dstChainId,
            abi.encode(formCommonData),
            abi.encode(formXChainData),
            stateData_.extraFormData
        );

        bytes memory formDataEncoded = abi.encode(formData);

        StateData memory info = StateData(
            TransactionType.WITHDRAW,
            CallbackType.INIT,
            formDataEncoded
        );

        txHistory[currentTotalTransactions] = info;

        /// @dev _liqReq should have path encoded for withdraw to SuperRouter on chain different than chainId
        /// @dev construct txData in this fashion: from FTM SOURCE send message to BSC DESTINATION
        /// @dev so that BSC DISPATCHTOKENS sends tokens to AVAX receiver (EOA/contract/user-specified)
        /// @dev sync could be a problem, how long Socket path stays vaild vs. how fast we bridge/receive on Dst
        stateRegistry.dispatchPayload{value: stateData_.msgValue}(
            stateData_.ambId,
            stateData_.dstChainId,
            abi.encode(info),
            stateData_.adapterParam
        );

        emit Initiated(
            currentTotalTransactions,
            liqData_.token,
            liqData_.amount
        );
    }

    /// @dev PREVILAGED admin ONLY FUNCTION.
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
            require(x != address(0), "Router: Zero Bridge Address");

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /// @dev allows registry contract to send payload for processing to the router contract.
    /// @param payload_ is the received information to be processed.
    function stateSync(bytes memory payload_) external payable override {
        require(msg.sender == address(stateRegistry), "Router: Request Denied");

        StateData memory data = abi.decode(payload_, (StateData));
        require(data.flag == CallbackType.RETURN, "Router: Invalid Payload");

        ReturnData memory returnData = abi.decode(data.params, (ReturnData));

        StateData memory stored = txHistory[returnData.txId];
        FormData memory formData = abi.decode(stored.params, (FormData));
        FormCommonData memory formCommonData = abi.decode(
            formData.commonData,
            (FormCommonData)
        );

        require(
            returnData.srcChainId == formData.srcChainId,
            "Router: Source Chain Ids Mismatch"
        );
        require(
            returnData.dstChainId == formData.dstChainId,
            "Router: Dst Chain Ids Mismatch"
        );

        if (data.txType == TransactionType.DEPOSIT) {
            require(returnData.status, "Router: Invalid Payload Status");
            _mintBatch(
                formCommonData.srcSender,
                formCommonData.superFormIds,
                returnData.amounts,
                ""
            );
        } else {
            require(!returnData.status, "Router: Invalid Payload Status");
            _mintBatch(
                formCommonData.srcSender,
                formCommonData.superFormIds,
                returnData.amounts,
                ""
            );
        }

        emit Completed(returnData.txId);
    }

    /*///////////////////////////////////////////////////////////////
                            Developmental Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev PREVILAGED admin ONLY FUNCTION.
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

    /// @dev PREVILAGED admin ONLY FUNCTION.
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
    ) internal pure returns (bool) {
        if (dstChainId_ != uint256(uint80(superFormData_.superFormId >> 176)))
            return false;

        if (
            superFormData_.maxSlippage < 0 || superFormData_.maxSlippage > 10000
        ) return false;

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
            if (
                dstChainId_ !=
                uint256(uint80(superFormsData_.superFormIds[i] >> 176))
            ) return false;

            if (
                superFormsData_.maxSlippage[i] < 0 ||
                superFormsData_.maxSlippage[i] > 10000
            ) return false;

            sumAmounts += superFormsData_.amounts[i];

            /// @dev TODO validate token correspond to superForms' underlying?
            /// @dev TODO validate TxData to avoid exploits
        }

        /// @dev if length = 1; amount = sum of superFormsData amount
        if (
            liqRequestsLen == 1 &&
            superFormsData_.liqRequests[0].amount != sumAmounts
        ) {
            return false;
            /// @dev else, length must be equal to the number of superForms sent in this request
        } else if (liqRequestsLen > 1) {
            if (liqRequestsLen != len) {
                return false;
            }
        }

        return true;
    }

    function _packTxData(
        address srcSender_,
        uint16 srcChainId_,
        uint80 currentTotalTxs_
    ) internal pure returns (uint256 txData) {
        txData = uint256(uint160(srcSender_));
        txData |= srcChainId_ << 160;
        txData |= uint256(currentTotalTxs_) << 176;
    }

    function _packTxInfo(
        uint128 txType_,
        uint128 callbackType_
    ) internal pure returns (uint256 txInfo) {
        txInfo = uint256(txType_);
        txInfo |= uint256(callbackType_) << 128;
    }
}
