/// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IMultiTxProcessor} from "../interfaces/IMultiTxProcessor.sol";
import {ISuperRegistry} from "../interfaces/ISuperRegistry.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {ISuperRBAC} from "../interfaces/ISuperRBAC.sol";
import {Error} from "../utils/Error.sol";

/// @title MultiTxProcessor
/// @author Zeropoint Labs.
/// @dev handles all destination chain swaps.
contract MultiTxProcessor is IMultiTxProcessor {
    using SafeERC20 for IERC20;

    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /*///////////////////////////////////////////////////////////////
                    State Variables
    //////////////////////////////////////////////////////////////*/

    ISuperRegistry public immutable superRegistry;

    modifier onlySwapper() {
        if (
            !ISuperRBAC(superRegistry.getAddress(superRegistry.SUPER_RBAC())).hasMultiTxProcessorSwapperRole(msg.sender)
        ) revert Error.NOT_SWAPPER();
        _;
    }

    modifier onlyEmergencyAdmin() {
        if (!ISuperRBAC(superRegistry.getAddress(superRegistry.SUPER_RBAC())).hasEmergencyAdminRole(msg.sender))
            revert Error.NOT_EMERGENCY_ADMIN();
        _;
    }

    /// @param superRegistry_        Superform registry contract
    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    /*///////////////////////////////////////////////////////////////
                            External Functions
    //////////////////////////////////////////////////////////////*/
    /// @notice receive enables processing native token transfers into the smart contract.
    /// @dev liquidity bridge fails without a native receive function.
    receive() external payable {}

    /// @inheritdoc IMultiTxProcessor
    function processTx(
        uint8 bridgeId_,
        bytes calldata txData_,
        address approvalToken_,
        uint256 amount_
    ) public override onlySwapper {
        uint64 chainId = superRegistry.chainId();

        /// @dev validates the bridge data
        IBridgeValidator(superRegistry.getBridgeValidator(bridgeId_)).validateTxData(
            txData_,
            chainId,
            chainId,
            false, /// to enter the if-else case of the bridge validator loop
            address(0),
            superRegistry.getAddress(superRegistry.CORE_STATE_REGISTRY()),
            approvalToken_
        );

        /// @dev get the address of the bridge to send the txData to.

        address to = superRegistry.getBridgeAddress(bridgeId_);
        if (approvalToken_ != NATIVE) {
            /// @dev approve the bridge to spend the approvalToken_.
            IERC20(approvalToken_).approve(to, amount_);
            /// @dev execute the txData_.
            (bool success, ) = payable(to).call(txData_);
            if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA();
        } else {
            /// @dev execute the txData_.
            (bool success, ) = payable(to).call{value: amount_}(txData_);
            if (!success) revert Error.FAILED_TO_EXECUTE_TXDATA_NATIVE();
        }
    }

    /// @inheritdoc IMultiTxProcessor
    function batchProcessTx(
        uint8[] calldata bridgeIds_,
        bytes[] calldata txData_,
        address[] calldata approvalTokens_,
        uint256[] calldata amounts_
    ) external override onlySwapper {
        for (uint256 i; i < txData_.length; ) {
            processTx(bridgeIds_[i], txData_[i], approvalTokens_[i], amounts_[i]);

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            EMERGENCY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev EMERGENCY_ADMIN ONLY FUNCTION.
    /// @dev allows admin to withdraw lost tokens in the smart contract.
    /// @param tokenContract_        address of the token contract
    /// @param amount_               amount of tokens to withdraw
    function emergencyWithdrawToken(address tokenContract_, uint256 amount_) external onlyEmergencyAdmin {
        IERC20 tokenContract = IERC20(tokenContract_);

        /// note: transfer the token from address of this contract
        /// note: to address of the user (executing the withdrawToken() function)
        tokenContract.safeTransfer(msg.sender, amount_);
    }

    /// @dev EMERGENCY_ADMIN ONLY FUNCTION.
    /// @dev allows admin to withdraw lost native tokens in the smart contract.
    /// @param amount_               amount of tokens to withdraw
    function emergencyWithdrawNativeToken(uint256 amount_) external onlyEmergencyAdmin {
        (bool success, ) = payable(msg.sender).call{value: amount_}("");
        if (!success) revert Error.NATIVE_TOKEN_TRANSFER_FAILURE();
    }
}
