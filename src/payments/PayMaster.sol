// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { LiquidityHandler } from "src/crosschain-liquidity/LiquidityHandler.sol";
import { IPayMaster } from "src/interfaces/IPayMaster.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { IAmbImplementation } from "src/interfaces/IAmbImplementation.sol";
import { Error } from "src/libraries/Error.sol";
import { LiqRequest } from "src/types/DataTypes.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title PayMaster
/// @dev Manages cross-chain payments and rebalancing of funds
/// @author ZeroPoint Labs
contract PayMaster is IPayMaster, LiquidityHandler {
    
    using SafeERC20 for IERC20;

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
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev to receive amb refunds
    receive() external payable { }

    /// @inheritdoc IPayMaster
    function withdrawTo(bytes32 superRegistryId_, address token_, uint256 amount_) external override onlyPaymentAdmin {
        if (amount_ == 0) {
            revert Error.ZERO_INPUT_VALUE();
        }
        if (token_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _withdraw(superRegistry.getAddress(superRegistryId_), token_, amount_);
    }

    /// @inheritdoc IPayMaster
    function withdrawNativeTo(bytes32 superRegistryId_, uint256 nativeAmount_) external override onlyPaymentAdmin {
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

    /// @dev helper to move tokens same chain
    function _withdraw(address receiver_, address token_, uint256 amount_) internal {
        IERC20 token = IERC20(token_);

        uint256 balance = token.balanceOf(address(this));
        if (balance < amount_) {
            revert Error.INSUFFICIENT_BALANCE();
        }
        token.safeTransfer(receiver_, amount_);

        emit TokenWithdrawn(receiver_, token_, amount_);
    }

    /// @dev helper to move native tokens same chain
    function _withdrawNative(address receiver_, uint256 amount_) internal {
        if (address(this).balance < amount_) {
            revert Error.FAILED_TO_SEND_NATIVE();
        }

        (bool success,) = payable(receiver_).call{ value: amount_ }("");

        if (!success) {
            revert Error.FAILED_TO_SEND_NATIVE();
        }

        emit NativeWithdrawn(receiver_, amount_);
    }

    /// @dev helper to move tokens cross-chain (native or not)
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
