// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626TimelockVault} from "./interfaces/IERC4626TimelockVault.sol";
import {InitSingleVaultData, TimeLockPayload} from "../types/DataTypes.sol";
import {LiqRequest} from "../types/LiquidityTypes.sol";
import {ERC4626FormImplementation} from "./ERC4626FormImplementation.sol";
import {BaseForm} from "../BaseForm.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {ITwoStepsFormStateRegistry} from "../interfaces/ITwoStepsFormStateRegistry.sol";
import {Error} from "../utils/Error.sol";

/// @title ERC4626TimelockForm
/// @notice Form implementation to handle timelock extension for ERC4626 vaults
contract ERC4626TimelockForm is ERC4626FormImplementation {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////*/
    modifier onlyTwoStepStateRegistry() {
        if (msg.sender != superRegistry.twoStepsFormStateRegistry()) {
            revert Error.NOT_TWO_STEP_STATE_REGISTRY();
        }
        _;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function withdrawAfterCoolDown(
        uint256 amount_,
        TimeLockPayload memory p_
    ) external onlyTwoStepStateRegistry returns (uint256 dstAmount) {
        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        LiqRequest memory liqData = p_.data.liqData;
        uint256 len1 = liqData.txData.length;
        address receiver = len1 == 0 ? p_.srcSender : address(this);

        /// @dev moves all redeemed tokens to the two step state registry
        dstAmount = v.redeem(amount_, receiver, address(this));

        /// @dev validate and dispatches the tokens
        if (len1 != 0) {
            /// @dev this check here might be too much already, but can't hurt
            if (liqData.amount > dstAmount) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            uint64 chainId = superRegistry.chainId();

            /// @dev NOTE: only allows withdraws to source chain if xchain / samechain in case of
            IBridgeValidator(superRegistry.getBridgeValidator(liqData.bridgeId)).validateTxData(
                liqData.txData,
                chainId,
                p_.isXChain == 1 ? p_.srcChainId : chainId,
                false,
                address(this),
                p_.srcSender,
                liqData.token
            );

            dispatchTokens(
                superRegistry.getBridgeAddress(liqData.bridgeId),
                liqData.txData,
                liqData.token,
                liqData.amount,
                address(this),
                liqData.nativeAmount, /// @dev be careful over here
                "",
                superRegistry.PERMIT2()
            );
        }
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal virtual override returns (uint256 dstAmount) {
        dstAmount = _processDirectDeposit(singleVaultData_, srcSender_);
    }

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for two step form withdrawal
    /// @dev will mandatorily process unlock
    /// @return dstAmount as always 0
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal virtual override returns (uint256 dstAmount) {
        uint256 lockedTill = _requestUnlock(singleVaultData_.amount);
        _storePayload(0, srcSender_, superRegistry.chainId(), lockedTill, singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address,
        uint64 srcChainId_
    ) internal virtual override returns (uint256 dstAmount) {
        dstAmount = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    ) internal virtual override returns (uint256 dstAmount) {
        uint256 lockedTill = _requestUnlock(singleVaultData_.amount);
        _storePayload(1, srcSender_, srcChainId_, lockedTill, singleVaultData_);
    }

    /// @dev calls the vault to request unlock
    /// @notice shares are successfully burned at this point
    function _requestUnlock(uint256 amount_) internal returns (uint256 lockedTill_) {
        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        v.requestUnlock(amount_, address(this));
        lockedTill_ = block.timestamp + v.getLockPeriod();
    }

    /// @dev stores the withdrawal payload
    function _storePayload(
        uint8 type_,
        address srcSender_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    ) internal {
        ITwoStepsFormStateRegistry registry = ITwoStepsFormStateRegistry(superRegistry.twoStepsFormStateRegistry());
        registry.receivePayload(type_, srcSender_, srcChainId_, lockedTill_, data_);
    }
}
