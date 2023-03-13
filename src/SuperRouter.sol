/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {LiqRequest} from "./types/LiquidityTypes.sol";
import {StateReq, StateData, TransactionType, ReturnData, CallbackType, FormData, FormCommonData, FormXChainData} from "./types/DataTypes.sol";
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
    uint256 public chainId;
    /// @dev totalTransactions keeps track of overall routed transactions.
    uint256 public totalTransactions;

    ISuperFormFactory public immutable factory;

    /// @notice history of state sent across chains are used for debugging.
    /// @dev maps all transaction data routed through the smart contract.
    mapping(uint256 => StateData) public txHistory;

    /// @notice bridge id is mapped to its execution address.
    /// @dev maps all the bridges to their address.
    mapping(uint8 => address) public bridgeAddress;

    /// @param chainId_              Layerzero chain id
    /// @param baseUri_              URL for external metadata of ERC1155 SuperPositions
    /// @param stateRegistry_         State registry address deployed
    /// @param factory_         SuperFormFactory address deployed
    constructor(
        uint16 chainId_,
        string memory baseUri_,
        IStateRegistry stateRegistry_,
        ISuperFormFactory factory_
    ) ERC1155(baseUri_) {
        if (chainId_ == 0) revert INVALID_INPUT_CHAIN_ID();

        chainId = chainId_;
        stateRegistry = stateRegistry_;
        factory = factory_;
    }

    /*///////////////////////////////////////////////////////////////
                        External Write Functions
    //////////////////////////////////////////////////////////////*/

    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev socket.tech fails without a native receive function.
    receive() external payable {}

    /// @dev allows users to mint vault tokens and receive vault positions in return.
    /// @param liqData_      represents the data required to move tokens from user wallet to destination contract.
    /// @param stateData_    represents the state information including destination vault ids and amounts to be deposited to such vaults.
    /// note: Just use single type not arr and delegate to SuperFormRouter?
    function deposit(
        LiqRequest[] calldata liqData_,
        StateReq[] calldata stateData_
    ) external payable override {
        /// @dev put msgSender() inside public functions for when they are accessed directly
        uint256 l1 = liqData_.length;
        uint256 l2 = stateData_.length;
        require(l1 == l2, "Router: Input Data Length Mismatch"); ///@dev ENG NOTE: but we may want to split single token deposit to multiple vaults on dst! this block it
        if (l1 > 1) {
            for (uint256 i = 0; i < l1; ++i) {
                if (stateData_[i].dstChainId == chainId) {
                    singleDirectDeposit(liqData_[i], stateData_[i]);
                } else {
                    singleXChainDeposit(liqData_[i], stateData_[i]);
                }
            }
        } else {
            if (stateData_[0].dstChainId == chainId) {
                singleDirectDeposit(liqData_[0], stateData_[0]);
            } else {
                singleXChainDeposit(liqData_[0], stateData_[0]);
            }
        }
    }

    /// @dev burns users superpositions and dispatch a withdrawal request to the destination chain.
    /// @param liqData_         represents the bridge data for underlying to be moved from destination chain.
    /// @param stateData_       represents the state data required for withdrawal of funds from the vaults.
    /// @dev API NOTE: This function can be called by anybody
    /// @dev ENG NOTE: Amounts is abstracted. 1:1 of positions on DESTINATION, but user can't query ie. previewWithdraw() cross-chain
    function withdraw(
        LiqRequest[] calldata liqData_, /// @dev Allow [] because user can request multiple tokens (as long as bridge has them - Needs check!)
        StateReq[] calldata stateData_
    ) external payable override {
        /// @dev put msgSender() inside public functions for when they are accessed directly

        uint256 l1 = stateData_.length;
        uint256 l2 = liqData_.length;

        require(l1 == l2, "Router: Invalid Input Length");
        if (l1 > 1) {
            for (uint256 i = 0; i < l1; ++i) {
                if (stateData_[i].dstChainId == chainId) {
                    singleDirectWithdraw(liqData_[i], stateData_[i]);
                } else {
                    singleXChainWithdraw(liqData_[i], stateData_[i]);
                }
            }
        } else {
            if (stateData_[0].dstChainId == chainId) {
                singleDirectWithdraw(liqData_[0], stateData_[0]);
            } else {
                singleXChainWithdraw(liqData_[0], stateData_[0]);
            }
        }
    }

    /// @notice validates input and call state registry & liquidity handler to move
    /// tokens and state messages to the destination chain.
    function singleDirectDeposit(
        LiqRequest calldata liqData_,
        StateReq calldata stateData_
    ) public payable override {
        if (stateData_.dstChainId != chainId) revert INVALID_INPUT_CHAIN_ID();

        address srcSender = _msgSender();

        totalTransactions++;
        /// @dev loading into memory here to save gas
        uint256 currentTotalTransactions = totalTransactions;

        /// @dev do we need to validate slippage for direct action?
        /// @dev TODO: turn into error
        require(
            _validateSlippage(stateData_.maxSlippage),
            "Super Router: Invalid Slippage"
        );

        /// @dev TODO Form Data Validatioooonnnn here

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
            TransactionType.DEPOSIT,
            CallbackType.INIT,
            formDataEncoded
        );

        txHistory[currentTotalTransactions] = info;

        /// @dev decode superforms
        /// @dev FIXME only one vault and form id are being returned currently!!!
        (, uint256[] memory formIds_, ) = factory.getSuperForms(
            stateData_.superFormIds
        );

        /// @dev deposits collateral to a given vault and mint vault positions.
        /// @dev FIXME: only one form id is being used here!
        uint256[] memory dstAmounts = IBaseForm(factory.getForm(formIds_[0]))
            .directDepositIntoVault{value: msg.value}(formDataEncoded);

        /// @dev TEST-CASE: _msgSender() to whom we mint. use passed `admin` arg?
        _mintBatch(srcSender, stateData_.superFormIds, dstAmounts, "");

        /// @dev doesn't seem relevant to emit these two events for direct actions. Delete?
        emit Completed(currentTotalTransactions);

        emit Initiated(
            currentTotalTransactions,
            liqData_.token,
            liqData_.amount
        );
    }

    function singleXChainDeposit(
        LiqRequest calldata liqData_,
        StateReq calldata stateData_
    ) public payable override {
        if (stateData_.dstChainId == chainId) revert INVALID_INPUT_CHAIN_ID();

        address srcSender = _msgSender();

        totalTransactions++;
        /// @dev loading into memory here to save gas
        uint256 currentTotalTransactions = totalTransactions;

        require(
            _validateSlippage(stateData_.maxSlippage),
            "Super Router: Invalid Slippage"
        );
        /// @dev TODO Form Data Validatioooonnnn here

        FormCommonData memory formCommonData = FormCommonData(
            srcSender,
            stateData_.superFormIds,
            stateData_.amounts,
            abi.encode(liqData_)
        );

        FormXChainData memory formXChainData = FormXChainData(
            currentTotalTransactions,
            stateData_.maxSlippage
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
            TransactionType.DEPOSIT,
            CallbackType.INIT,
            formDataEncoded
        );

        txHistory[currentTotalTransactions] = info;

        dispatchTokens(
            bridgeAddress[liqData_.bridgeId],
            liqData_.txData,
            liqData_.token,
            liqData_.allowanceTarget,
            liqData_.amount,
            srcSender,
            liqData_.nativeAmount
        );

        /// @dev LayerZero endpoint
        stateRegistry.dispatchPayload{value: stateData_.msgValue}(
            stateData_.bridgeId,
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
        (, uint256[] memory formIds_, ) = factory.getSuperForms(
            stateData_.superFormIds
        );

        /// @dev FIXME only one form id is being used here!
        /// @dev to allow bridging somewhere else requires arch change
        IBaseForm(factory.getForm(formIds_[0])).directWithdrawFromVault{
            value: msg.value
        }(formDataEncoded);

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
            stateData_.bridgeId,
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
}
