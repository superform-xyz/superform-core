// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ERC4626FormImplementation } from "src/forms/ERC4626FormImplementation.sol";
import { BaseForm } from "src/BaseForm.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { ITimelockStateRegistry } from "src/interfaces/ITimelockStateRegistry.sol";
import { IEmergencyQueue } from "src/interfaces/IEmergencyQueue.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { Error } from "src/libraries/Error.sol";
import { InitSingleVaultData, TimelockPayload, LiqRequest } from "src/types/DataTypes.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626TimelockVault } from "super-vaults/interfaces/IERC4626TimelockVault.sol";

/// @title ERC4626TimelockForm
/// @dev Form implementation to handle timelock extension for ERC4626 vaults
/// @author Zeropoint Labs
contract ERC4626TimelockForm is ERC4626FormImplementation {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC4626TimelockVault;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    uint8 constant stateRegistryId = 2; // TimelockStateRegistry

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                         //
    //////////////////////////////////////////////////////////////

    struct WithdrawAfterCoolDownLocalVars {
        uint256 len1;
        address bridgeValidator;
        uint64 chainId;
        address receiver;
        address asset;
        uint256 amount;
        LiqRequest liqData;
    }

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyTimelockStateRegistry() {
        if (msg.sender != superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY"))) {
            revert Error.NOT_TIMELOCK_STATE_REGISTRY();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_, stateRegistryId) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev this function is called when the timelock deposit is ready to be withdrawn after being unlocked
    /// @dev retain4626 flag is not added in this implementation unlike in ERC4626Implementation.sol because
    /// @dev if a vault fails to redeem at this stage, superPositions are minted back to the user and he can
    /// @dev try again with retain4626 flag set and take their shares directly
    /// @param p_ the payload data
    function withdrawAfterCoolDown(TimelockPayload memory p_)
        external
        onlyTimelockStateRegistry
        returns (uint256 assets)
    {
        if (p_.data.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();

        if (_isPaused(p_.data.superformId)) {
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(p_.data);

            return 0;
        }
        WithdrawAfterCoolDownLocalVars memory vars;

        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        vars.liqData = p_.data.liqData;
        vars.len1 = vars.liqData.txData.length;

        /// @dev a case where the withdraw req liqData has a valid token and tx data is not updated by the keeper
        if (vars.liqData.token != address(0) && vars.len1 == 0) {
            revert Error.WITHDRAW_TX_DATA_NOT_UPDATED();
        } else if (vars.liqData.token == address(0) && vars.len1 != 0) {
            revert Error.WITHDRAW_TOKEN_NOT_UPDATED();
        }

        /// @dev if the txData is empty, the tokens are sent directly to the sender, otherwise sent first to this form
        vars.receiver = vars.len1 == 0 ? p_.data.receiverAddress : address(this);

        /// @dev redeem from vault
        vars.asset = asset;
        IERC20 assetERC = IERC20(vars.asset);

        uint256 assetsBalanceBefore = assetERC.balanceOf(vars.receiver);
        assets = v.redeem(p_.data.amount, vars.receiver, address(this));
        uint256 assetsBalanceAfter = assetERC.balanceOf(vars.receiver);
        if (assetsBalanceAfter - assetsBalanceBefore != assets) {
            revert Error.VAULT_IMPLEMENTATION_FAILED();
        }
        if (assets == 0) revert Error.WITHDRAW_ZERO_COLLATERAL();

        /// @dev validate and dispatches the tokens
        if (vars.len1 != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(vars.liqData.bridgeId);
            vars.amount = IBridgeValidator(vars.bridgeValidator).decodeAmountIn(vars.liqData.txData, false);

            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            if (vars.amount > assets) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

            vars.chainId = CHAIN_ID;

            /// @dev validate and perform the swap to desired output token and send to beneficiary
            IBridgeValidator(superRegistry.getBridgeValidator(vars.liqData.bridgeId)).validateTxData(
                IBridgeValidator.ValidateTxDataArgs(
                    vars.liqData.txData,
                    vars.chainId,
                    p_.isXChain == 1 ? p_.srcChainId : vars.chainId,
                    vars.liqData.liqDstChainId,
                    false,
                    address(this),
                    p_.data.receiverAddress,
                    vars.asset,
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(vars.liqData.bridgeId),
                vars.liqData.txData,
                vars.asset,
                vars.amount,
                vars.liqData.nativeAmount
            );
        }
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BaseForm
    function _directDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        virtual
        override
        returns (uint256 shares)
    {
        shares = _processDirectDeposit(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address, /*srcSender_*/
        uint64 srcChainId_
    )
        internal
        virtual
        override
        returns (uint256 shares)
    {
        shares = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for timelock form withdrawal, direct case
    /// @dev will mandatorily process unlock unless the retain4626 flag is set
    /// @return shares is always 0
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address /*srcSender_*/
    )
        internal
        virtual
        override
        returns (uint256)
    {
        if (!singleVaultData_.retain4626) {
            /// @dev after requesting the unlock, the information with the time of full unlock is saved and sent to
            /// timelock
            /// @dev state registry for re-processing at a later date
            _storePayload(0, CHAIN_ID, _requestUnlock(singleVaultData_.amount), singleVaultData_);
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            IERC4626TimelockVault(vault).safeTransfer(singleVaultData_.receiverAddress, singleVaultData_.amount);
        }
        return 0;
    }

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for timelock form withdrawal, xchain case
    /// @dev will mandatorily process unlock unless the retain4626 flag is set
    /// @return shares is always 0
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address, /*srcSender_*/
        uint64 srcChainId_
    )
        internal
        virtual
        override
        returns (uint256)
    {
        if (!singleVaultData_.retain4626) {
            /// @dev after requesting the unlock, the information with the time of full unlock is saved and sent to
            /// timelock
            /// @dev state registry for re-processing at a later date
            _storePayload(1, srcChainId_, _requestUnlock(singleVaultData_.amount), singleVaultData_);
        } else {
            /// @dev transfer shares to user and do not redeem shares for assets
            IERC4626TimelockVault(vault).safeTransfer(singleVaultData_.receiverAddress, singleVaultData_.amount);
        }

        return 0;
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address receiverAddress_, uint256 amount_) internal override {
        _processEmergencyWithdraw(receiverAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster(address token_) internal override {
        _processForwardDustToPaymaster(token_);
    }

    /// @dev calls the vault to request unlock
    /// @notice superPositions are already burned at this point
    function _requestUnlock(uint256 amount_) internal returns (uint256 lockedTill_) {
        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        v.requestUnlock(amount_, address(this));
        lockedTill_ = block.timestamp + v.getLockPeriod();
    }

    /// @dev stores the withdrawal payload
    function _storePayload(
        uint8 type_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    )
        internal
    {
        ITimelockStateRegistry(superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY"))).receivePayload(
            type_, srcChainId_, lockedTill_, data_
        );
    }
}
