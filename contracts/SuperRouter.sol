/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {LiqRequest} from "./types/socketTypes.sol";
import {StateReq, StateData, TransactionType, ReturnData, CallbackType, InitData} from "./types/lzTypes.sol";

import {IStateHandler} from "./interface/layerzero/IStateHandler.sol";
import {IDestination} from "./interface/IDestination.sol";

import "./socket/liquidityHandler.sol";

import {SafeTransferLib} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

/**
 * @title Super Router
 * @author Zeropoint Labs.
 *
 * Routes users funds and deposit information to a remote execution chain.
 * extends ERC1155 and Socket's Liquidity Handler.
 * @notice access controlled was removed due to contract sizing issues.
 */
contract SuperRouter is ERC1155, LiquidityHandler, Ownable {
    using SafeTransferLib for ERC20;
    using SafeERC20 for IERC20;
    using Strings for string;

    /* ================ State Variables =================== */
    string public name = "SuperPositions";
    string public symbol = "SP";
    string public dynamicURI = "https://api.superform.xyz/superposition/";

    /**
     * @notice state = information about destination chain & vault id.
     * @notice  stateHandler accepts requests from whitelisted addresses.
     * @dev stateHandler integrates with interblockchain messaging protocols.
     */
    IStateHandler public stateHandler;

    /**
     * @notice chainId represents layerzero's unique chain id for each chains.
     * @notice admin handles critical state updates.
     * @dev totalTransactions keeps track of overall routed transactions.
     */
    uint16 public chainId;
    uint256 public totalTransactions;

    /**
     * @notice same chain deposits are processed in one atomic transaction flow.
     * @dev allows to store same chain destination contract addresses.
     */
    IDestination public immutable srcSuperDestination;

    /**
     * @notice history of state sent across chains are used for debugging.
     * @dev maps all transaction data routed through the smart contract.
     */
    mapping(uint256 => StateData) public txHistory;

    /**
     * @notice bridge id is mapped to its execution address.
     * @dev maps all the bridges to their address.
     */
    mapping(uint8 => address) public bridgeAddress;

    /* ================ Events =================== */

    event Initiated(uint256 txId, address fromToken, uint256 fromAmount);
    event Completed(uint256 txId);

    event SetBridgeAddress(uint256 bridgeId, address bridgeAddress);

    /* ================ Constructor =================== */

    /**
     * @notice deploy stateHandler and SuperDestination before SuperRouter
     *
     * @param chainId_              Layerzero chain id
     * @param baseUri_              URL for external metadata of ERC1155 SuperPositions
     * @param stateHandler_         State handler address deployed
     * @param srcSuperDestination_  Destination address deployed on same chain
     */
    constructor(
        uint16 chainId_,
        string memory baseUri_,
        IStateHandler stateHandler_,
        IDestination srcSuperDestination_
    ) ERC1155(baseUri_) {
        srcSuperDestination = srcSuperDestination_;
        stateHandler = stateHandler_;
        chainId = chainId_;
    }

    /* ================ External Functions =================== */
    /**
     * @notice receive enables processing native token transfers into the smart contract.
     * @dev socket.tech fails without a native receive function.
     */
    receive() external payable {}

    /* ================ Write Functions =================== */

    /**
     * @dev allows users to mint vault tokens and receive vault positions in return.
     *
     * @param _liqData      represents the data required to move tokens from user wallet to destination contract.
     * @param _stateData    represents the state information including destination vault ids and amounts to be deposited to such vaults.
     *
     * ENG NOTE: Just use single type not arr and delegate to SuperFormRouter?
     */
    function deposit(
        LiqRequest[] calldata _liqData,
        StateReq[] calldata _stateData
    ) external payable {
        address srcSender = _msgSender();
        uint256 l1 = _liqData.length;
        uint256 l2 = _stateData.length;
        require(l1 == l2, "Router: Input Data Length Mismatch"); ///@dev ENG NOTE: but we may want to split single token deposit to multiple vaults on dst! this block it
        if (l1 > 1) {
            for (uint256 i = 0; i < l1; ++i) {
                singleDeposit(_liqData[i], _stateData[i], srcSender);
            }
        } else {
            singleDeposit(_liqData[0], _stateData[0], srcSender);
        }
    }

    /**
     * @dev burns users superpositions and dispatch a withdrawal request to the destination chain.
      
     * @param _stateReq       represents the state data required for withdrawal of funds from the vaults.
     * @param _liqReq         represents the bridge data for underlying to be moved from destination chain.

     * @dev API NOTE: This function can be called by anybody
     * @dev ENG NOTE: Amounts is abstracted. 1:1 of positions on DESTINATION, but user can't query ie. previewWithdraw() cross-chain
     */
    function withdraw(
        StateReq[] calldata _stateReq,
        LiqRequest[] calldata _liqReq /// @dev Allow [] because user can request multiple tokens (as long as bridge has them - Needs check!)
    ) external payable {
        address sender = _msgSender();
        uint256 l1 = _stateReq.length;
        uint256 l2 = _liqReq.length;

        require(l1 == l2, "Router: Invalid Input Length");
        if (l1 > 1) {
            for (uint256 i = 0; i < l1; ++i) {
                singleWithdrawal(_liqReq[i], _stateReq[i], sender);
            }
        } else {
            singleWithdrawal(_liqReq[0], _stateReq[0], sender);
        }
    }

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @dev allows admin to set the bridge address for an bridge id.
     * @param _bridgeId         represents the bridge unqiue identifier.
     * @param _bridgeAddress    represents the bridge address.
     */
    function setBridgeAddress(
        uint8[] memory _bridgeId,
        address[] memory _bridgeAddress
    ) external onlyOwner {
        for (uint256 i = 0; i < _bridgeId.length; i++) {
            address x = _bridgeAddress[i];
            uint8 y = _bridgeId[i];
            require(x != address(0), "Router: Zero Bridge Address");

            bridgeAddress[y] = x;
            emit SetBridgeAddress(y, x);
        }
    }

    /* ================ Development Only Functions =================== */

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @notice should be removed after end-to-end testing.
     * @dev allows admin to withdraw lost tokens in the smart contract.
     */
    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(owner(), _amount);
    }

    /**
     * PREVILAGED admin ONLY FUNCTION.
     * @dev allows admin to withdraw lost native tokens in the smart contract.
     */
    function withdrawNativeToken(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    /**
     * ANYONE CAN CALL THE FUNCTION.
     *
     * @dev processes state channel messages from destination chain post successful deposit to a vault.
     * @param _payload  represents internal transactionId associated with every deposit/withdrawal transaction.
     */
    function stateSync(bytes memory _payload) external payable {
        require(msg.sender == address(stateHandler), "Router: Request Denied");

        StateData memory data = abi.decode(_payload, (StateData));
        require(data.flag == CallbackType.RETURN, "Router: Invalid Payload");

        ReturnData memory returnData = abi.decode(data.params, (ReturnData));

        StateData memory stored = txHistory[returnData.txId];
        InitData memory initData = abi.decode(stored.params, (InitData));

        require(
            returnData.srcChainId == initData.srcChainId,
            "Router: Source Chain Ids Mismatch"
        );
        require(
            returnData.dstChainId == initData.dstChainId,
            "Router: Dst Chain Ids Mismatch"
        );

        if (data.txType == TransactionType.DEPOSIT) {
            require(returnData.status, "Router: Invalid Payload Status");
            _mintBatch(
                initData.user,
                initData.vaultIds,
                returnData.amounts,
                ""
            );
        } else {
            require(!returnData.status, "Router: Invalid Payload Status");
            _mintBatch(
                initData.user,
                initData.vaultIds,
                returnData.amounts,
                ""
            );
        }

        emit Completed(returnData.txId);
    }

    /**
     * Function to support Metadata hosting in Opensea.
     */
    function tokenURI(uint256 id) public view returns (string memory) {
        return
            string(abi.encodePacked(dynamicURI, Strings.toString(id), ".json"));
    }

    /* ================ Internal Functions =================== */

    /**
     * @notice validates input and call state handler & liquidity handler to move
     * tokens and state messages to the destination chain.
     */
    function singleDeposit(
        LiqRequest calldata _liqData,
        StateReq calldata _stateData,
        address srcSender
    ) internal {
        totalTransactions++;
        uint16 dstChainId = _stateData.dstChainId;

        require(
            validateSlippage(_stateData.maxSlippage),
            "Super Router: Invalid Slippage"
        );

        InitData memory initData = InitData(
            chainId,
            dstChainId,
            srcSender,
            _stateData.vaultIds,
            _stateData.amounts,
            _stateData.maxSlippage,
            totalTransactions,
            bytes("")
        );

        /// Only passed when chainId != dstChainId
        StateData memory info = StateData(
            TransactionType.DEPOSIT,
            CallbackType.INIT,
            abi.encode(initData)
        );

        txHistory[totalTransactions] = info;

        if (chainId == dstChainId) {
            dstDeposit(_liqData, _stateData, srcSender, totalTransactions);
        } else {
            
            /// NOTE: How do we validate that _liqData.amount is >= stateData.amounts
            /// We can't pass uniqueId with liqData to match against stateData on dst...
            /// To test: Attacker listens for deposit event and makes an optimistic call to reach dst before the user.
            /// Attacker hopes to use user's liquidity to fill his stateData.amounts request
            /// NOTE: Old SUP-633 Related. Issue on both Router & Destination.
            dispatchTokens(
                bridgeAddress[_liqData.bridgeId],
                _liqData.txData,
                _liqData.token,
                _liqData.isERC20, /// NOTE: Allowance target == bridgeAddress above
                _liqData.amount,
                srcSender,
                _liqData.nativeAmount
            );

            /// @dev LayerZero endpoint
            stateHandler.dispatchState{value: _stateData.msgValue}(
                dstChainId,
                abi.encode(info),
                _stateData.adapterParam
            );
        }

        emit Initiated(totalTransactions, _liqData.token, _liqData.amount);
    }

    /**
     * @notice validates input and initiates withdrawal process
     */
    function singleWithdrawal(
        LiqRequest calldata _liqData,
        StateReq calldata _stateData,
        address sender
    ) internal {
        uint16 dstChainId = _stateData.dstChainId;

        require(dstChainId != 0, "Router: Invalid Destination Chain");
        /// NOTE: Here we can burn ANY vaultId!!!
        /// attacker can use any sp position in burn for any other position with crafted liqData
        _burnBatch(sender, _stateData.vaultIds, _stateData.amounts);

        totalTransactions++;

        InitData memory initData = InitData(
            chainId,
            _stateData.dstChainId,
            sender,
            _stateData.vaultIds,
            _stateData.amounts,
            _stateData.maxSlippage,
            totalTransactions,
            abi.encode(_liqData)
        );

        StateData memory info = StateData(
            TransactionType.WITHDRAW,
            CallbackType.INIT,
            abi.encode(initData)
        );

        txHistory[totalTransactions] = info;

        LiqRequest memory data = _liqData;

        if (chainId == dstChainId) {
            /// @dev srcSuperDestination can only transfer tokens back to this SuperRouter
            /// @dev to allow bridging somewhere else requires arch change
            srcSuperDestination.directWithdraw{value: msg.value}(
                sender,
                _stateData.vaultIds,
                _stateData.amounts,
                data
            );

            emit Completed(totalTransactions);
        } else {
            /// @dev _liqReq should have path encoded for withdraw to SuperRouter on chain different than chainId
            /// @dev construct txData in this fashion: from FTM SOURCE send message to BSC DESTINATION
            /// @dev so that BSC DISPATCHTOKENS sends tokens to AVAX receiver (EOA/contract/user-specified)
            /// @dev sync could be a problem, how long Socket path stays vaild vs. how fast we bridge/receive on Dst
            stateHandler.dispatchState{value: _stateData.msgValue}(
                dstChainId,
                abi.encode(info),
                _stateData.adapterParam
            );
        }

        emit Initiated(totalTransactions, _liqData.token, _liqData.amount);
    }

    /**
     * @notice deposit() to vaults existing on the same chain as SuperRouter
     * @dev Optimistic transfer & call
     */
    function dstDeposit(
        LiqRequest calldata _liqData,
        StateReq calldata _stateData,
        address srcSender,
        uint256 txId
    ) internal {
        /// @dev deposits collateral to a given vault and mint vault positions.
        uint256[] memory dstAmounts = srcSuperDestination.directDeposit{
            value: msg.value
        }(srcSender, _liqData, _stateData.vaultIds, _stateData.amounts);

        /// @dev TEST-CASE: _msgSender() to whom we mint. use passed `admin` arg?
        _mintBatch(srcSender, _stateData.vaultIds, dstAmounts, "");
        emit Completed(txId);
    }

    /**
     * @dev validates slippage parameter;
     * slippages should always be within 0 - 100
     * decimal is handles in the form of 10s
     * for eg. 0.05 = 5
     *         100 = 10000
     */
    function validateSlippage(uint256[] calldata slippages)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < slippages.length; i++) {
            if (slippages[i] < 0 || slippages[i] > 10000) {
                return false;
            }
        }
        return true;
    }

    function addValues(uint256[] calldata amounts)
        internal
        pure
        returns (uint256)
    {
        uint256 total;
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
        return total;
    }
}
