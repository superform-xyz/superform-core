// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { ISocketRegistry } from "src/vendor/socket/ISocketRegistry.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISocketValidator } from "src/interfaces/ISocketValidator.sol";

import "forge-std/console.sol";

/// @title SocketValidator
/// @dev Asserts Socket x-chain input txData is valid
/// @author Zeropoint Labs
contract SocketValidator is ISocketValidator, BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    /// @dev mapping to store the blacklisted route ids
    mapping(uint256 routeId => bool blacklisted) private blacklistedRouteIds;
    uint64 public immutable CHAIN_ID;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasEmergencyAdminRole(msg.sender)) {
            revert Error.NOT_EMERGENCY_ADMIN();
        }
        _;
    }
    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) {
        CHAIN_ID = uint64(block.chainid);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISocketValidator
    function addToBlacklist(uint256 id_) external override onlyEmergencyAdmin {
        if (blacklistedRouteIds[id_]) revert Error.BLACKLISTED_ROUTE_ID();

        blacklistedRouteIds[id_] = true;
        emit AddedToBlacklist(id_);
    }

    /// @inheritdoc ISocketValidator
    function removeFromBlacklist(uint256 id_) external override onlyEmergencyAdmin {
        if (!blacklistedRouteIds[id_]) revert Error.NOT_BLACKLISTED_ROUTE_ID();

        delete blacklistedRouteIds[id_];
        emit RemovedFromBlacklist(id_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc ISocketValidator
    function isRouteBlacklisted(uint256 id_) public view override returns (bool blacklisted) {
        return blacklistedRouteIds[id_];
    }

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external pure override returns (bool) {
        return (receiver == _decodeTxData(txData_).receiverAddress);
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        ISocketRegistry.UserRequest memory decodedReq = _decodeTxData(args_.txData);

        // Check if the route id is blacklisted
        if (isRouteBlacklisted(decodedReq.bridgeRequest.id)) {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        console.log("decodedReq.toChainId: %s", decodedReq.toChainId); // wrong one
        console.log("args_.liqDstChainId: %s", uint256(args_.liqDstChainId));

        /// @dev 1. chain id validation (only allow xChain with this)
        if (decodedReq.toChainId != uint256(args_.liqDstChainId)) revert Error.INVALID_TXDATA_CHAIN_ID();

        /// @dev 2. receiver address validation
        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId) {
                revert Error.INVALID_ACTION();
            } else {
                hasDstSwap = decodedReq.receiverAddress
                    == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);

                /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
                if (
                    !(
                        decodedReq.receiverAddress
                            == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                            || hasDstSwap
                    )
                ) {
                    revert Error.INVALID_TXDATA_RECEIVER();
                }

                /// @dev forbid xChain deposits with destination swaps without interim token set (for user
                /// protection)
                if (hasDstSwap && args_.liqDataInterimToken == address(0)) {
                    revert Error.INVALID_INTERIM_TOKEN();
                }
            }
        } else {
            /// @dev if withdraws, then receiver address must be the receiverAddress
            if (decodedReq.receiverAddress != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
        }

        /// @dev token validations
        if (
            (decodedReq.middlewareRequest.id == 0 && args_.liqDataToken != decodedReq.bridgeRequest.inputToken)
                || (decodedReq.middlewareRequest.id != 0 && args_.liqDataToken != decodedReq.middlewareRequest.inputToken)
        ) revert Error.INVALID_TXDATA_TOKEN();
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool /*genericSwapDisallowed_*/
    )
        external
        pure
        override
        returns (uint256 amount_)
    {
        amount_ = _decodeTxData(txData_).amount;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata /*txData_*/ )
        external
        pure
        override
        returns (address, /*token_*/ uint256 /*amount_*/ )
    {
        /// @dev SocketValidator cannot be used for just swaps, see SocketOneinchValidator
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {
        /// @dev SocketValidator cannot be used for just swaps, see SocketOneinchValidator
        revert Error.CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helps decode socket user request
    /// returns the user request
    function _decodeTxData(bytes calldata txData_)
        internal
        pure
        returns (ISocketRegistry.UserRequest memory userRequest)
    {
        userRequest = abi.decode(_parseCallData(txData_), (ISocketRegistry.UserRequest));
    }

    /// @dev helps parsing socket calldata and return the socket request
    function _parseCallData(bytes calldata callData) internal pure returns (bytes calldata) {
        return callData[4:];
    }
}
