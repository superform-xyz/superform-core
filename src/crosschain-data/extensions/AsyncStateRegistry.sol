// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { IBaseForm } from "src/interfaces/IBaseForm.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { ISuperPositions } from "src/interfaces/ISuperPositions.sol";
import {
    IAsyncStateRegistry,
    ClaimAvailableDepositsArgs,
    ClaimAvailableDepositsLocalVars,
    NOT_READY_TO_CLAIM,
    ERC7540_AMBIDS_NOT_ENCODED,
    INVALID_AMOUNT_IN_TXDATA,
    REQUEST_CONFIG_NON_EXISTENT,
    RequestConfig
} from "src/interfaces/IAsyncStateRegistry.sol";

import { IERC7540Form } from "src/forms/interfaces/IERC7540Form.sol";
import { Error } from "src/libraries/Error.sol";
import { ProofLib } from "src/libraries/ProofLib.sol";
import { DataLib } from "src/libraries/DataLib.sol";
import { PayloadUpdaterLib } from "src/libraries/PayloadUpdaterLib.sol";
import {
    InitSingleVaultData,
    AMBMessage,
    CallbackType,
    TransactionType,
    ReturnSingleData,
    LiqRequest
} from "src/types/DataTypes.sol";
import { BaseAsyncStateRegistry } from "./BaseAsyncStateRegistry.sol";

/// @title AsyncStateRegistry
/// @dev Handles communication in 7540 forms with constant zero request ids
/// @author Zeropoint Labs
contract AsyncStateRegistry is BaseAsyncStateRegistry, IAsyncStateRegistry {
    using DataLib for uint256;
    using ProofLib for AMBMessage;

    //////////////////////////////////////////////////////////////
    //                     STATE VARIABLES                      //
    //////////////////////////////////////////////////////////////

    // 0 for unset, 1 for non fungible, 2 for fungible
    uint8 public immutable ASYNC_STATE_REGISRY_TYPE;

    mapping(address user => mapping(uint256 superformId => RequestConfig requestConfig)) public requestConfigs;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(ISuperRegistry superRegistry_) BaseAsyncStateRegistry(superRegistry_) { }
    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAsyncStateRegistry
    function getRequestConfig(address user_, uint256 superformId_) external view returns (RequestConfig memory) {
        return requestConfigs[user_][superformId_];
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IAsyncStateRegistry
    function updateRequestConfig(
        uint8 type_,
        uint64 srcChainId_,
        bool isDeposit_,
        uint256 requestId_,
        InitSingleVaultData memory data_
    )
        external
        override
        onlyAsyncSuperform(data_.superformId)
    {
        /// @dev note that as per the standard, if requestId_ is returned as 0, it means it will always be zero
        RequestConfig storage config = requestConfigs[data_.receiverAddress][data_.superformId];

        if (data_.receiverAddress == address(0)) revert Error.RECEIVER_ADDRESS_NOT_SET();
        uint8[] memory ambIds;
        bool is7540;

        config.isXChain = type_;

        config.retain4626 = data_.retain4626;

        config.currentSrcChainId = srcChainId_;

        if (requestId_ != 0) config.requestId = requestId_;

        /// @dev decode payloadId with txHistory and check if multi == 1 if so, do not update
        /// TODO
        config.currentReturnDataPayloadId = data_.payloadId;

        config.maxSlippageSetting = data_.maxSlippage;

        if (!isDeposit_) config.currentLiqRequest = data_.liqData;

        if (type_ == 1) {
            (is7540, ambIds) = _decode7540ExtraFormData(data_.superformId, data_.extraFormData);
            if (!(is7540 && ambIds.length > 0)) revert ERC7540_AMBIDS_NOT_ENCODED();
            config.ambIds = ambIds;

            /// @dev TODO can check ambs length is greater than quorum
        }

        emit UpdatedRequestsConfig(data_.receiverAddress, data_.superformId, requestId_);
    }

    /// @inheritdoc IAsyncStateRegistry
    function claimAvailableDeposits(ClaimAvailableDepositsArgs memory args_)
        external
        payable
        override
        onlyAsyncStateRegistryProcessor
    {
        ClaimAvailableDepositsLocalVars memory v;

        RequestConfig memory config = requestConfigs[args_.user][args_.superformId];

        if (config.currentSrcChainId == 0) {
            revert REQUEST_CONFIG_NON_EXISTENT();
        }

        (v.superformAddress,,) = args_.superformId.getSuperform();

        IERC7540Form superform = IERC7540Form(v.superformAddress);

        v.claimableDeposit = superform.getClaimableDepositRequest(config.requestId, args_.user);

        if (v.claimableDeposit == 0) {
            revert NOT_READY_TO_CLAIM();
        }

        try superform.claimDeposit(args_.user, args_.superformId, v.claimableDeposit, config.retain4626) returns (
            uint256 shares
        ) {
            if (shares != 0 && !config.retain4626) {
                /// @dev dispatch acknowledgement to mint superPositions
                if (config.isXChain == 1) {
                    _dispatchAcknowledgement(
                        config.currentSrcChainId,
                        config.ambIds,
                        abi.encode(
                            AMBMessage(
                                DataLib.packTxInfo(
                                    uint8(TransactionType.DEPOSIT),
                                    uint8(CallbackType.RETURN),
                                    0,
                                    _getStateRegistryId(),
                                    args_.user,
                                    CHAIN_ID
                                ),
                                abi.encode(
                                    ReturnSingleData(config.currentReturnDataPayloadId, args_.superformId, shares)
                                )
                            )
                        )
                    );
                }

                /// @dev for direct chain, superPositions are minted directly
                if (config.isXChain == 0) {
                    ISuperPositions(_getSuperRegistryAddress(keccak256("SUPER_POSITIONS"))).mintSingle(
                        args_.user, args_.superformId, shares
                    );
                }
            } else if (shares == 0) {
                emit FailedDepositClaim(args_.user, args_.superformId, config.requestId);
            }
        } catch {
            /// @dev In case of a deposit actual failure (at the vault level, or returned shares level in the form),
            /// @dev the course of action for a user to claim the deposit would be to directly call claim deposit at the
            /// vault contract level.
            /// @dev This must happen like this because superform does not have the shares nor the assets to act upon
            /// them.

            emit FailedDepositClaim(args_.user, args_.superformId, config.requestId);
        }

        emit ClaimedAvailableDeposits(args_.user, args_.superformId, config.requestId);
    }

    /// @inheritdoc IAsyncStateRegistry
    function claimAvailableRedeems(
        address user_,
        uint256 superformId_,
        bytes memory updatedTxData_
    )
        external
        override
        onlyAsyncStateRegistryProcessor
    {
        RequestConfig storage config = requestConfigs[user_][superformId_];

        if (config.currentSrcChainId == 0) {
            revert REQUEST_CONFIG_NON_EXISTENT();
        }

        (address superformAddress,,) = superformId_.getSuperform();

        /// @dev validate that account exists (aka User must do at least one deposit to initiate this procedure)

        IERC7540Form superform = IERC7540Form(superformAddress);

        uint256 claimableRedeem = superform.getClaimableRedeemRequest(config.requestId, user_);

        if (claimableRedeem == 0) {
            revert NOT_READY_TO_CLAIM();
        }

        /// @dev this step is used to feed txData in case user wants to receive assets in a different way
        if (updatedTxData_.length != 0) {
            _validateTxDataAsync(
                config.currentSrcChainId,
                claimableRedeem,
                updatedTxData_,
                config.currentLiqRequest,
                user_,
                superformAddress
            );

            config.currentLiqRequest.txData = updatedTxData_;
        }

        /// @dev if redeeming failed superPositions are not reminted
        /// @dev this is different than the normal 4626 flow because if a redeem is claimable
        /// @dev a user could simply go to the vault and claim the assets directly
        superform.claimWithdraw(
            user_,
            superformId_,
            claimableRedeem,
            config.maxSlippageSetting,
            config.isXChain,
            config.currentSrcChainId,
            config.currentLiqRequest
        );

        emit ClaimedAvailableRedeems(user_, superformId_, config.requestId);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    function _validateTxDataAsync(
        uint64 srcChainId_,
        uint256 claimableRedeem_,
        bytes memory txData_,
        LiqRequest memory liqData_,
        address user_,
        address superformAddress_
    )
        internal
        view
    {
        IBaseForm superform = IBaseForm(superformAddress_);
        PayloadUpdaterLib.validateLiqReq(liqData_);

        IBridgeValidator bridgeValidator = IBridgeValidator(superRegistry.getBridgeValidator(liqData_.bridgeId));

        bridgeValidator.validateTxData(
            IBridgeValidator.ValidateTxDataArgs(
                txData_,
                CHAIN_ID,
                srcChainId_,
                liqData_.liqDstChainId,
                false,
                superformAddress_,
                user_,
                superform.getVaultAsset(),
                address(0)
            )
        );

        if (bridgeValidator.decodeAmountIn(txData_, false) != claimableRedeem_) {
            revert INVALID_AMOUNT_IN_TXDATA();
        }
    }
}
