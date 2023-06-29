// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "forge-std/console.sol";

import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626TimelockVault} from "./interfaces/IERC4626TimelockVault.sol";
import {InitSingleVaultData, AMBMessage, InitMultiVaultData} from "../types/DataTypes.sol";
import {ERC4626FormImplementation} from "./ERC4626FormImplementation.sol";
import {BaseForm} from "../BaseForm.sol";
import {IBaseStateRegistry} from "../interfaces/IBaseStateRegistry.sol";
import {IBridgeValidator} from "../interfaces/IBridgeValidator.sol";
import {ITwoStepsFormStateRegistry} from "../interfaces/ITwoStepsFormStateRegistry.sol";
import {Error} from "../utils/Error.sol";
import "../utils/DataPacking.sol";

/// @title ERC4626TimelockForm
/// @notice Form implementation to handle timelock extension for ERC4626 vaults
contract ERC4626TimelockForm is ERC4626FormImplementation {
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address superRegistry_) ERC4626FormImplementation(superRegistry_) {}

    /*///////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function withdrawAfterCoolDown(uint256 amount_, address receiver_) external {
        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        v.redeem(amount_, receiver_, address(this));
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
        uint256 lockedTill = _processUnlock(singleVaultData_.amount);

        /// @dev record the unlock on two step form state registry
        address twoStepFormStateRegistry = superRegistry.twoStepsFormStateRegistry();
        ITwoStepsFormStateRegistry(twoStepFormStateRegistry).receivePayload(
            1, /// @dev indicates same_chain
            srcSender_,
            singleVaultData_.superFormId,
            singleVaultData_.amount,
            lockedTill,
            0,
            0
        );
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
        uint256 lockedTill = _processUnlock(singleVaultData_.amount);

        /// @dev record the unlock on two step form state registry
        address twoStepFormStateRegistry = superRegistry.twoStepsFormStateRegistry();
        ITwoStepsFormStateRegistry(twoStepFormStateRegistry).receivePayload(
            1, /// @dev indicates same_chain
            srcSender_,
            singleVaultData_.superFormId,
            singleVaultData_.amount,
            lockedTill,
            0,
            0
        );
    }

    /// @dev calls the vault to request unlock
    /// @notice shares are successfully burned at this point
    function _processUnlock(uint256 amount_) internal returns (uint256 lockedTill_) {
        IERC4626TimelockVault v = IERC4626TimelockVault(vault);

        v.requestUnlock(amount_, address(this));
        lockedTill_ = block.timestamp + v.getLockPeriod();
    }

    /// @dev reads a payload from core state registry and construct
    /// single init vault data
    function getSingleVaultDataAtIndex(
        uint256 payloadId_,
        uint256 index_
    ) public view returns (InitSingleVaultData memory data, address, uint64) {
        bytes memory payloadBody = IBaseStateRegistry(superRegistry.coreStateRegistry()).payloadBody(payloadId_);
        uint256 payloadHeader = IBaseStateRegistry(superRegistry.coreStateRegistry()).payloadHeader(payloadId_);

        (, , , , address srcSender, uint64 srcChainId) = _decodeTxInfo(payloadHeader);

        InitMultiVaultData memory multiVaultData = abi.decode(payloadBody, (InitMultiVaultData));

        data = InitSingleVaultData({
            payloadId: multiVaultData.payloadId,
            superFormId: multiVaultData.superFormIds[index_],
            amount: multiVaultData.amounts[index_],
            maxSlippage: multiVaultData.maxSlippage[index_],
            liqData: multiVaultData.liqData[index_],
            extraFormData: abi.encode(payloadId_, index_)
        });
    }
}
