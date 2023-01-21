/**
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import {IStateHandler} from "./interface/layerzero/IStateHandler.sol";
import {IController} from "./interface/ISource.sol";
import {IDestination} from "./interface/IDestination.sol";

import {StateReq, InitData, StateData, TransactionType, CallbackType} from "./types/lzTypes.sol";
import {LiqRequest} from "./types/socketTypes.sol";

contract RouterPatch is ERC1155Holder {
    address public constant ROUTER_ADDRESS =
        0xfF3aFb7d847AeD8f2540f7b5042F693242e01ebD;
    address public constant STATE_ADDRESS =
        0x908da814cc9725616D410b2978E88fF2fb9482eE;
    address public constant DESTINATION_ADDRESS =
        0xc8884edE1ae44bDfF60da4B9c542C34A69648A87;

    uint256 public totalTransactions;
    uint16 public chainId;

    /* ================ Mapping =================== */
    mapping(uint256 => StateData) public txHistory;

    /* ================ Events =================== */
    event Initiated(uint256 txId, address fromToken, uint256 fromAmount);
    event Completed(uint256 txId);

    constructor(uint16 chainId_) {
        chainId = chainId_;
        totalTransactions = IController(ROUTER_ADDRESS).totalTransactions();
    }

    function withdraw(
        StateReq[] calldata _stateReq,
        LiqRequest[] calldata _liqReq
    ) external {
        address sender = msg.sender;
        uint256 l1 = _stateReq.length;
        uint256 l2 = _liqReq.length;

        require(l1 == l2, "Router: Invalid Input Length");
        if (l1 > 1) {
            for (uint256 i = 0; i < l1; ++i) {
                singleWithdrawal(_stateReq[i], sender);
            }
        } else {
            singleWithdrawal(_stateReq[0], sender);
        }
    }

    function singleWithdrawal(StateReq calldata _stateData, address sender)
        internal
    {
        uint16 dstChainId = _stateData.dstChainId;
        require(dstChainId != 0, "Router: Invalid Destination Chain");

        /// burn is not exposed externally; TBD: whether to move them here and burn.
        IERC1155(ROUTER_ADDRESS).safeBatchTransferFrom(
            sender,
            address(this),
            _stateData.vaultIds,
            _stateData.amounts,
            "0x"
        );

        totalTransactions++;

        /// generating a dummy request - that will override user's inbound req
        LiqRequest memory data = LiqRequest(
            0,
            "0x",
            address(0),
            true,
            0,
            0
        );

        InitData memory initData = InitData(
            chainId,
            _stateData.dstChainId,
            sender,
            _stateData.vaultIds,
            _stateData.amounts,
            _stateData.maxSlippage,
            totalTransactions,
            abi.encode(data)
        );

        StateData memory info = StateData(
            TransactionType.WITHDRAW,
            CallbackType.INIT,
            abi.encode(initData)
        );

        txHistory[totalTransactions] = info;

        if (chainId == dstChainId) {
            /// @dev srcSuperDestination can only transfer tokens back to this SuperRouter
            /// @dev to allow bridging somewhere else requires arch change
            IDestination(DESTINATION_ADDRESS).directWithdraw(
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
            IStateHandler(STATE_ADDRESS).dispatchState{
                value: _stateData.msgValue
            }(dstChainId, abi.encode(info), _stateData.adapterParam);
        }

        emit Initiated(totalTransactions, address(0), 0);
    }
}
