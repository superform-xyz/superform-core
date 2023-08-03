// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Error} from "./utils/Error.sol";

import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";
import {IBridgeValidator} from "./interfaces/IBridgeValidator.sol";

import {LiquidityHandler} from "./crosschain-liquidity/LiquidityHandler.sol";

import "./types/LiquidityTypes.sol";

/// @title FeeCollector
/// @author ZeroPoint Labs
contract FeeCollector is IFeeCollector, LiquidityHandler {
    /*///////////////////////////////////////////////////////////////
                       STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    ISuperRegistry public superRegistry;
    mapping(address => uint256) public totalFeesPaid;

    /*///////////////////////////////////////////////////////////////
                        MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlyFeeAdmin() {
        if (!ISuperRBAC(superRegistry.superRBAC()).hasFeeAdminRole(msg.sender)) {
            revert Error.INVALID_CALLER();
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

    /// @inheritdoc IFeeCollector
    function withdrawToMultiTxProcessor(uint256 nativeAmount_) external onlyFeeAdmin {
        if (nativeAmount_ > address(this).balance) {
            revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        address receiver = superRegistry.multiTxProcessor();
        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _withdrawNative(receiver, nativeAmount_);
    }

    /// @inheritdoc IFeeCollector
    function withdrawToTxProcessor(uint256 nativeAmount_) external onlyFeeAdmin {
        if (nativeAmount_ > address(this).balance) {
            revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        address receiver = superRegistry.txProcessor();
        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _withdrawNative(receiver, nativeAmount_);
    }

    /// @inheritdoc IFeeCollector
    function withdrawToTxUpdater(uint256 nativeAmount_) external onlyFeeAdmin {
        if (nativeAmount_ > address(this).balance) {
            revert Error.INSUFFICIENT_NATIVE_AMOUNT();
        }

        address receiver = superRegistry.txUpdater();
        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _withdrawNative(receiver, nativeAmount_);
    }

    /// @inheritdoc IFeeCollector
    function rebalanceToMultiTxProcessor(LiqRequest memory req_) external onlyFeeAdmin {
        /// assuming all multi-tx processor across chains should be same; CREATE2
        address receiver = superRegistry.multiTxProcessor();

        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _validateAndDispatchTokens(req_, receiver);
    }

    /// @inheritdoc IFeeCollector
    function rebalanceToTxProcessor(LiqRequest memory req_) external onlyFeeAdmin {
        /// assuming all tx processor across chains should be same; CREATE2
        address receiver = superRegistry.txProcessor();

        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _validateAndDispatchTokens(req_, receiver);
    }

    /// @inheritdoc IFeeCollector
    function rebalanceToTxUpdater(LiqRequest memory req_) external onlyFeeAdmin {
        /// assuming all tx updater across chains should be same; CREATE2
        address receiver = superRegistry.txUpdater();

        if (receiver == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        _validateAndDispatchTokens(req_, receiver);
    }

    /*///////////////////////////////////////////////////////////////
                    EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFeeCollector
    function makePayment(address user_) external payable {
        if (msg.value == 0) {
            revert Error.ZERO_MSG_VALUE();
        }

        if (user_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        totalFeesPaid[user_] += msg.value;

        emit FeesPaid(user_, msg.value);
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL/HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev helper to move native tokens same chain
    function _withdrawNative(address receiver_, uint256 amount_) internal {
        (bool success, ) = payable(receiver_).call{value: amount_}("");

        if (!success) {
            revert Error.FAILED_WITHDRAW();
        }

        emit FeesWithdrawn(receiver_, amount_);
    }

    /// @dev helper to move native tokens cross-chain
    function _validateAndDispatchTokens(LiqRequest memory liqRequest_, address receiver_) internal {
        bool valid = IBridgeValidator(superRegistry.getBridgeValidator(liqRequest_.bridgeId)).validateReceiver(
            liqRequest_.txData,
            receiver_
        );

        if (!valid) {
            revert Error.INVALID_TXDATA_RECEIVER();
        }

        dispatchTokens(
            superRegistry.getBridgeAddress(liqRequest_.bridgeId),
            liqRequest_.txData,
            liqRequest_.token,
            liqRequest_.amount,
            msg.sender,
            liqRequest_.nativeAmount,
            liqRequest_.permit2data,
            superRegistry.PERMIT2()
        );
    }
}
