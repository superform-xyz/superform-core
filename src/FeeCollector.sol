// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {Error} from "./utils/Error.sol";

import {ISuperRBAC} from "./interfaces/ISuperRBAC.sol";
import {IFeeCollector} from "./interfaces/IFeeCollector.sol";
import {ISuperRegistry} from "./interfaces/ISuperRegistry.sol";

/// @title FeeCollector
/// @author ZeroPoint Labs
contract FeeCollector is IFeeCollector {
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
                    PREVILAGED ADMIN FUNCTIONS
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
    function _withdrawNative(address receiver_, uint256 amount_) internal {
        (bool success, ) = payable(receiver_).call{value: amount_}("");

        if (!success) {
            revert Error.FAILED_WITHDRAW();
        }

        emit FeesWithdrawn(receiver_, amount_);
    }
}
