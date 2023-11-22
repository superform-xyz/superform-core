// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.23;

import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC4626TimelockVault } from "super-vaults/interfaces/IERC4626TimelockVault.sol";
import { InitSingleVaultData, TimelockPayload, LiqRequest } from "../types/DataTypes.sol";
import { ERC4626FormImplementation } from "./ERC4626FormImplementation.sol";
import { BaseForm } from "../BaseForm.sol";
import { IBridgeValidator } from "../interfaces/IBridgeValidator.sol";
import { ITimelockStateRegistry } from "../interfaces/ITimelockStateRegistry.sol";
import { IEmergencyQueue } from "../interfaces/IEmergencyQueue.sol";
import { DataLib } from "../libraries/DataLib.sol";
import { Error } from "../libraries/Error.sol";

/// @title ERC4626TimelockForm
/// @notice Form implementation to handle timelock extension for ERC4626 vaults
contract ERC4626TimelockForm is ERC4626FormImplementation {
    using SafeERC20 for IERC20;
    using DataLib for uint256;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    uint8 constant stateRegistryId = 2; // TimelockStateRegistry

    //////////////////////////////////////////////////////////////
    //                           STRUCTS                         //
    //////////////////////////////////////////////////////////////

    struct withdrawAfterCoolDownLocalVars {
        uint256 len1;
        address bridgeValidator;
        uint64 chainId;
        address receiver;
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
    /// @param p_ the payload data
    function withdrawAfterCoolDown(TimelockPayload memory p_)
        external
        onlyTimelockStateRegistry
        returns (uint256 dstAmount)
    {
        if (_isPaused(p_.data.superformId)) {
            IEmergencyQueue(superRegistry.getAddress(keccak256("EMERGENCY_QUEUE"))).queueWithdrawal(
                p_.data, p_.srcSender
            );
            return 0;
        }
        withdrawAfterCoolDownLocalVars memory vars;

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

        dstAmount = v.redeem(p_.data.amount, vars.receiver, address(this));
        /// @dev validate and dispatches the tokens
        if (vars.len1 != 0) {
            vars.bridgeValidator = superRegistry.getBridgeValidator(vars.liqData.bridgeId);
            vars.amount = IBridgeValidator(vars.bridgeValidator).decodeAmountIn(vars.liqData.txData, false);

            /// @dev the amount inscribed in liqData must be less or equal than the amount redeemed from the vault
            if (vars.amount > dstAmount) revert Error.DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

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
                    vars.liqData.token,
                    address(0)
                )
            );

            _dispatchTokens(
                superRegistry.getBridgeAddress(vars.liqData.bridgeId),
                vars.liqData.txData,
                vars.liqData.token,
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
        returns (uint256 dstAmount)
    {
        dstAmount = _processDirectDeposit(singleVaultData_);
    }

    /// @inheritdoc BaseForm
    function _xChainDepositIntoVault(
        InitSingleVaultData memory singleVaultData_,
        address,
        uint64 srcChainId_
    )
        internal
        virtual
        override
        returns (uint256 dstAmount)
    {
        dstAmount = _processXChainDeposit(singleVaultData_, srcChainId_);
    }

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for timelock form withdrawal, direct case
    /// @dev will mandatorily process unlock
    /// @return dstAmount is always 0
    function _directWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_
    )
        internal
        virtual
        override
        returns (uint256)
    {
        /// @dev after requesting the unlock, the information with the time of full unlock is saved and sent to timelock
        /// @dev state registry for re-processing at a later date
        _storePayload(0, srcSender_, CHAIN_ID, _requestUnlock(singleVaultData_.amount), singleVaultData_);

        return 0;
    }

    /// @inheritdoc BaseForm
    /// @dev this is the step-1 for timelock form withdrawal, xchain case
    /// @dev will mandatorily process unlock
    /// @return dstAmount is always 0
    function _xChainWithdrawFromVault(
        InitSingleVaultData memory singleVaultData_,
        address srcSender_,
        uint64 srcChainId_
    )
        internal
        virtual
        override
        returns (uint256)
    {
        /// @dev after requesting the unlock, the information with the time of full unlock is saved and sent to timelock
        /// @dev state registry for re-processing at a later date
        _storePayload(1, srcSender_, srcChainId_, _requestUnlock(singleVaultData_.amount), singleVaultData_);

        return 0;
    }

    /// @inheritdoc BaseForm
    function _emergencyWithdraw(address, /*srcSender_*/ address refundAddress_, uint256 amount_) internal override {
        _processEmergencyWithdraw(refundAddress_, amount_);
    }

    /// @inheritdoc BaseForm
    function _forwardDustToPaymaster() internal override {
        _processForwardDustToPaymaster();
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
        address srcSender_,
        uint64 srcChainId_,
        uint256 lockedTill_,
        InitSingleVaultData memory data_
    )
        internal
    {
        ITimelockStateRegistry(superRegistry.getAddress(keccak256("TIMELOCK_STATE_REGISTRY"))).receivePayload(
            type_, srcSender_, srcChainId_, lockedTill_, data_
        );
    }
}
