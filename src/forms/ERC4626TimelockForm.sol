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
    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, 4) {}

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev this function is called when the timelock deposit is ready to be withdrawn after being unlocked
    /// @param amount_ the amount of tokens to withdraw
    /// @param p_ the payload data
    function withdrawAfterCoolDown(
        uint256 amount_,
        TimeLockPayload memory p_
    ) external onlyTwoStepStateRegistry returns (uint256 dstAmount) {
        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        LiqRequest memory liqData = p_.data.liqData;
        uint256 len1 = liqData.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (liqData.token != address(0) && len1 == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        }

        /// @dev if the txData is empty, the tokens are sent directly to the sender, otherwise sent first to this form
        address receiver = len1 == 0 ? p_.srcSender : address(this);

        dstAmount = v.redeem(amount_, receiver, address(this));

        /// @dev validate and dispatches the tokens
        if (len1 != 0) {
            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            if (liqData.amount > dstAmount) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            uint64 chainId = superRegistry.chainId();

            /// @dev validate and perform the swap to desired output token and send to beneficiary
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
    /// @dev this is the step-1 for two step form withdrawal, direct case
    /// @dev will mandatorily process unlock
    /// @return dstAmount is always 0
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    ) internal virtual override returns (uint256 dstAmount) {
        uint256 lockedTill = _requestUnlock(singleVaultData_.amount);
        /// @dev after requesting the unlock, the information with the time of full unlock is saved and sent to the two step
        /// @dev state registry for re-processing at a later date
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
    /// @dev this is the step-1 for two step form withdrawal, xchain case
    /// @dev will mandatorily process unlock
    /// @return dstAmount is always 0
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    ) internal virtual override returns (uint256 dstAmount) {
        uint256 lockedTill = _requestUnlock(singleVaultData_.amount);
        /// @dev after requesting the unlock, the information with the time of full unlock is saved and sent to the two step
        /// @dev state registry for re-processing at a later date
        _storePayload(1, srcSender_, srcChainId_, lockedTill, singleVaultData_);
    }

    /// @dev calls the vault to request unlock
    /// @notice shares are already burned at this point
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
