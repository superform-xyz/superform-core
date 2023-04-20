// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {BridgeValidator} from "../BridgeValidator.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ISocketRegistry} from "../../interfaces/ISocketRegistry.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";

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
                                Errors
    //////////////////////////////////////////////////////////////*/
    error INVALID_SOCKET_CHAIN_ID();

    /*///////////////////////////////////////////////////////////////
                                Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        ISuperRegistry superRegistry_
    ) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_
    ) external view override returns (bool) {
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(
            txData_
        );

        /// @dev chainId validation
        if (socketChainId[dstChainId_] != userRequest.toChainId)
            revert INVALID_SOCKET_CHAIN_ID();

        /// @dev receiver address validation
        if (
            srcChainId_ == dstChainId_ ||
            (!deposit_ && srcChainId_ != dstChainId_)
        ) {
            /// @dev If action is same chain or cross chain withdraw, then receiver address must be the superform

            if (userRequest.receiverAddress != superForm_)
                revert Error.INVALID_RECEIVER();
        } else {
            /// @dev if cross chain deposits, then receiver address must be the token bank

            if (userRequest.receiverAddress != superRegistry.tokenBank())
                revert Error.INVALID_RECEIVER();
        }

        /// @dev input token validation
        address vaultUnderlying = address(
            IBaseForm(superForm_).getUnderlyingOfVault()
        );
        if (
            srcChainId_ == dstChainId_ &&
            userRequest.middlewareRequest.inputToken != vaultUnderlying
        ) {
            /// @dev directAction validation (MiddlewareRequest)

            revert Error.INVALID_INPUT_TOKEN();
        } else if (
            /// @dev crossChainAction validation ()

            srcChainId_ != dstChainId_ &&
            userRequest.bridgeRequest.inputToken != vaultUnderlying
        ) {
            revert Error.INVALID_INPUT_TOKEN();
        }

        return true;
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainId_ is the identifier of the chain within superform protocol
    /// @param socketChainId_ is the identifier of the chain given by the bridge
    function setChainId(
        uint16 superChainId_,
        uint256 socketChainId_
    ) external onlyProtocolAdmin {
        if (superChainId_ == 0 || superChainId_ == 0) {
            revert Error.INVALID_CHAIN_ID();
        }

        socketChainId[superChainId_] = socketChainId_;

        emit ChainIdSet(superChainId_, socketChainId_);
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
