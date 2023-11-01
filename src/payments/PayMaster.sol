// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { Error } from "../utils/Error.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { IPayMaster } from "../interfaces/IPayMaster.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import { ILayerZeroEndpoint } from "../vendor/layerzero/ILayerZeroEndpoint.sol";
import { IInterchainGasPaymaster } from "../vendor/hyperlane/IInterchainGasPaymaster.sol";
import { IWormholeRelayerSend, VaaKey } from "../vendor/wormhole/IWormholeRelayer.sol";
import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";
import "../types/LiquidityTypes.sol";

/// @title PayMaster
/// @author ZeroPoint Labs
contract PayMaster is IPayMaster, LiquidityHandler {
    /*///////////////////////////////////////////////////////////////
                       STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public superRegistry;
    mapping(address => uint256) public totalFeesPaid;

    /*///////////////////////////////////////////////////////////////
                        MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlyPaymentAdmin() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("PAYMENT_ADMIN_ROLE"), msg.sender
            )
        ) {
            revert Error.NOT_PAYMENT_ADMIN();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                        CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                    PRIVILEGED ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPayMaster
    function withdrawTo(bytes32 superRegistryId_, uint256 nativeAmount_) external override onlyPaymentAdmin {
        if (nativeAmount_ > address(this).balance) {
            revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        address receiver = superRegistry.getAddress(superRegistryId_);
        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _withdrawNative(receiver, nativeAmount_);
    }

    /// @inheritdoc IPayMaster
    function rebalanceTo(
        bytes32 superRegistryId_,
        LiqRequest memory req_,
        uint64 dstChainId_
    )
        external
        override
        onlyPaymentAdmin
    {
        address receiver = superRegistry.getAddressByChainId(superRegistryId_, dstChainId_);

        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _validateAndDispatchTokens(req_, receiver);
    }

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPayMaster
    function makePayment(address user_) external payable override {
        if (msg.value == 0) {
            revert Error.ZERO_MSG_VALUE();
        }

        if (user_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        totalFeesPaid[user_] += msg.value;

        emit Payment(user_, msg.value);
    }

    function treatLayerzero(uint16 srcChainId_, bytes calldata srcAddress_, bytes memory payload_) external {
        /// FIXME: figure out how to get this
        ILayerZeroEndpoint(address(0)).retryPayload(srcChainId_, srcAddress_, payload_);
    }

    function treatHyperlane(
        bytes32 messageId_,
        uint32 destinationDomain_,
        uint256 gasAmount_,
        address refundAddress_
    )
        external
        payable
    {
        /// FIXME: figure out how to get this
        /// FIXME: validate refund address
        IInterchainGasPaymaster(address(0)).payForGas{ value: msg.value }(
            messageId_, destinationDomain_, gasAmount_, refundAddress_
        );
    }

    function testWormhole(
        VaaKey memory deliveryVaaKey_,
        uint16 targetChain_,
        uint256 newReceiverValue_,
        uint256 newGasLimit_,
        address newDeliveryProviderAddress_
    )
        external
        payable
    {
        IWormholeRelayerSend(address(0)).resendToEvm{ value: msg.value }(
            deliveryVaaKey_, targetChain_, newReceiverValue_, newGasLimit_, newDeliveryProviderAddress_
        );
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev helper to move native tokens same chain
    function _withdrawNative(address receiver_, uint256 amount_) internal {
        if (receiver_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        (bool success,) = payable(receiver_).call{ value: amount_ }("");

        if (!success) {
            revert Error.FAILED_WITHDRAW();
        }

        emit PaymentWithdrawn(receiver_, amount_);
    }

    /// @dev helper to move native tokens cross-chain
    function _validateAndDispatchTokens(LiqRequest memory liqRequest_, address receiver_) internal {
        address bridgeValidator = superRegistry.getBridgeValidator(liqRequest_.bridgeId);

        bool valid = IBridgeValidator(bridgeValidator).validateReceiver(liqRequest_.txData, receiver_);

        if (!valid) {
            revert Error.INVALID_TXDATA_RECEIVER();
        }

        valid = IBridgeValidator(bridgeValidator).validateLiqDstChainId(liqRequest_.txData, liqRequest_.liqDstChainId);

        if (!valid) {
            revert Error.INVALID_TXDATA_CHAIN_ID();
        }

        _dispatchTokens(
            superRegistry.getBridgeAddress(liqRequest_.bridgeId),
            liqRequest_.txData,
            liqRequest_.token,
            IBridgeValidator(bridgeValidator).decodeAmountIn(liqRequest_.txData, true),
            liqRequest_.nativeAmount
        );
    }
}
