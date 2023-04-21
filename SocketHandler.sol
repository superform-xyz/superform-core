// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LiquidityBridgeHandler} from "../LiquidityBridgeHandler.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {ISocketRegistry} from "../../interfaces/ISocketRegistry.sol";
import {IBaseForm} from "../../interfaces/IBaseForm.sol";
import {Error} from "../../utils/Error.sol";

import "forge-std/console.sol";

/// @title Socket handler contract
/// @author Zeropoint Labs
/// @dev To assert input txData is valid
contract SocketHandler is LiquidityBridgeHandler {
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

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev dispatches tokens via the bridge.
    /// @param bridge_ Bridge address to pass tokens to
    /// @param txData_ Socket data
    /// @param token_ Token caller deposits into superform
    /// @param amount_ Amount of tokens to deposit
    /// @param owner_ Owner of tokens
    /// @param nativeAmount_ msg.value or msg.value + native tokens
    /// @param permit2Data_ abi.encode of nonce, deadline & signature for the amounts being transfered
    function dispatchTokens(
        address bridge_,
        bytes memory txData_,
        address token_,
        uint256 amount_,
        address owner_,
        uint256 nativeAmount_,
        bytes memory permit2Data_,
        address permit2_
    ) external override {
        /// @dev liquidity bridge specific decoding
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(
            txData_
        );

        /// NOTE: Delegatecall is always risky. bridge_ address hardcoded now.
        /// Can't we just use bridge interface here?
        unchecked {
            (bool success, ) = payable(bridge_).call{value: nativeAmount_}(
                txData_
            );
            if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA();
        }
    }

    /// @dev allows admin to add new chain ids in future
    /// @param superChainIds_ are the identifier of the chain within superform protocol
    /// @param socketChainIds_ are the identifier of the chain given by the bridge
    function setChainIds(
        uint16[] memory superChainIds_,
        uint256[] memory socketChainIds_
    ) external onlyProtocolAdmin {
        for (uint256 i = 0; i < socketChainIds_.length; i++) {
            uint16 superChainIdT = superChainIds_[i];
            uint256 socketChainIdT = socketChainIds_[i];
            if (superChainIdT == 0 || socketChainIdT == 0) {
                revert Error.INVALID_CHAIN_ID();
            }

            socketChainId[superChainIdT] = socketChainIdT;

            emit ChainIdSet(superChainIdT, socketChainIdT);
        }
    }

    function validateTxData(
        bytes calldata txData_,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_
    ) external view override returns (bool) {
        /// @dev liquidity bridge specific decoding
        ISocketRegistry.UserRequest memory userRequest = _decodeCallData(
            txData_
        );

        _validateTxData(
            userRequest,
            srcChainId_,
            dstChainId_,
            deposit_,
            superForm_
        );

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _validateTxData(
        ISocketRegistry.UserRequest,
        uint16 srcChainId_,
        uint16 dstChainId_,
        bool deposit_,
        address superForm_
    ) internal view {
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

        /// @dev usage of middlwareRequest or bridge request does not necessarily have to do with src and dst chain id being the same!
        /// @dev FIXME
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
