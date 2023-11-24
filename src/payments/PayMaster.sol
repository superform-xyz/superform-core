// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { Error } from "../libraries/Error.sol";
import { ISuperRBAC } from "../interfaces/ISuperRBAC.sol";
import { IPayMaster } from "../interfaces/IPayMaster.sol";
import { ISuperRegistry } from "../interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import { IAmbImplementation } from "../interfaces/IAmbImplementation.sol";
import { LiquidityHandler } from "../crosschain-liquidity/LiquidityHandler.sol";
import { LiqRequest } from "../types/DataTypes.sol";

/// @title PayMaster
/// @author ZeroPoint Labs
contract PayMaster is IPayMaster, LiquidityHandler {
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    mapping(address => uint256) public totalFeesPaid;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

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

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev to receive amb refunds
    receive() external payable { }

    /// @inheritdoc IPayMaster
    function withdrawTo(bytes32 superRegistryId_, uint256 nativeAmount_) external override onlyPaymentAdmin {
        if (nativeAmount_ > address(this).balance) {
            revert Error.FAILED_TO_SEND_NATIVE();
        }

        _withdrawNative(superRegistry.getAddress(superRegistryId_), nativeAmount_);
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
        /// receiver cannot be address(0)
        address receiver = superRegistry.getAddressByChainId(superRegistryId_, dstChainId_);
        _validateAndDispatchTokens(req_, receiver);
    }

    /// @inheritdoc IPayMaster
    function treatAMB(uint8 ambId_, uint256 nativeValue_, bytes memory data_) external override onlyPaymentAdmin {
        if (address(this).balance < nativeValue_) {
            revert Error.FAILED_TO_SEND_NATIVE();
        }

        IAmbImplementation(superRegistry.getAmbAddress(ambId_)).retryPayload{ value: nativeValue_ }(data_);
    }

    /// @inheritdoc IPayMaster
    function makePayment(address user_) external payable override {
        if (msg.value == 0) {
            revert Error.FAILED_TO_SEND_NATIVE();
        }

        if (user_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        totalFeesPaid[user_] += msg.value;

        emit Payment(user_, msg.value);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @dev helper to move native tokens same chain
    function _withdrawNative(address receiver_, uint256 amount_) internal {
        (bool success,) = payable(receiver_).call{ value: amount_ }("");

        if (!success) {
            revert Error.FAILED_TO_SEND_NATIVE();
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

        _dispatchTokens(
            superRegistry.getBridgeAddress(liqRequest_.bridgeId),
            liqRequest_.txData,
            liqRequest_.token,
            IBridgeValidator(bridgeValidator).decodeAmountIn(liqRequest_.txData, true),
            liqRequest_.nativeAmount
        );
    }
}
