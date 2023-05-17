// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {MultiVaultsSFData, SingleVaultSFData} from "../../types/DataTypes.sol";
import {BridgeValidator} from "../BridgeValidator.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ISocketRegistry} from "../../vendor/socket/ISocketRegistry.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

/// @title Socket verification contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract SocketValidator is BridgeValidator {
    mapping(uint16 => uint256) public socketChainId;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/
    event ChainIdSet(uint16 superChainId, uint256 socketChainId);

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BridgeValidator
    function validateTxDataAmount(
        bytes calldata txData_,
        uint256 amount_
    ) external pure override returns (bool) {
        if ((_decodeCallData(txData_).amount != amount_)) {
            return false;
        }

        return true;
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_,
        address srcSender_,
        address liqDataToken_
    ) external view override {
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(
            txData_
        );

        /// @dev 1. chainId validation
        if (socketChainId[dstChainId_] != userRequest.toChainId)
            revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation

        if (deposit_ && srcChainId_ == dstChainId_) {
            /// @dev If same chain deposits then receiver address must be the superform

            if (userRequest.receiverAddress != superForm_)
                revert Error.INVALID_TXDATA_RECEIVER();
        } else if (deposit_ && srcChainId_ != dstChainId_) {
            /// @dev if cross chain deposits, then receiver address must be the token bank
            if (
                !(userRequest.receiverAddress ==
                    superRegistry.coreStateRegistry() ||
                    userRequest.receiverAddress ==
                    superRegistry.multiTxProcessor())
            ) revert Error.INVALID_TXDATA_RECEIVER();
        } else if (!deposit_) {
            /// @dev if withdraws, then receiver address must be the srcSender
            /// @dev what if SrcSender is a contract? can it be used to re-enter somewhere?
            /// https://linear.app/superform/issue/SUP-2024/reentrancy-vulnerability-prevent-crafting-arbitrary-txdata-to-reenter
            if (userRequest.receiverAddress != srcSender_)
                revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev 3. token validation
        if (
            userRequest.middlewareRequest.id == 0 &&
            liqDataToken_ != userRequest.bridgeRequest.inputToken
        ) {
            revert Error.INVALID_TXDATA_TOKEN();
        } else if (
            userRequest.middlewareRequest.id != 0 &&
            liqDataToken_ != userRequest.middlewareRequest.inputToken
        ) {
            revert Error.INVALID_TXDATA_TOKEN();
        }
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainIds_ is the identifier of the chain within superform protocol
    /// @param socketChainIds_ is the identifier of the chain given by the bridge
    function setChainIds(
        uint16[] memory superChainIds_,
        uint256[] memory socketChainIds_
    ) external onlyProtocolAdmin {
        for (uint256 i = 0; i < superChainIds_.length; i++) {
            uint16 superChainIdT = superChainIds_[i];
            uint256 socketChainIdT = socketChainIds_[i];
            if (superChainIdT == 0 || socketChainIdT == 0) {
                revert Error.INVALID_CHAIN_ID();
            }

            socketChainId[superChainIdT] = socketChainIdT;

            emit ChainIdSet(superChainIdT, socketChainIdT);
        }
    }

    /// @notice Decode the socket v2 calldata
    /// @param data Socket V2 outboundTransferTo call data
    /// @return userRequest socket UserRequest
    function _decodeCallData(
        bytes calldata data
    ) internal pure returns (ISocketRegistry.UserRequest memory userRequest) {
        (userRequest) = abi.decode(data[4:], (ISocketRegistry.UserRequest));
    }
}
