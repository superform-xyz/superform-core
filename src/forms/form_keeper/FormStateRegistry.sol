// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {ISuperRBAC} from "../../interfaces/ISuperRBAC.sol";
import {ISuperRegistry} from "../../interfaces/ISuperRegistry.sol";
import {IERC4626Timelock} from ".././interfaces/IERC4626Timelock.sol";
import {IFormStateRegistry} from "./IFormStateRegistry.sol";
import {Error} from "../../utils/Error.sol";
import "../../utils/DataPacking.sol";

import {BaseStateRegistry} from "../../crosschain-data/BaseStateRegistry.sol";
import {ITokenBank} from "../../interfaces/ITokenBank.sol";
import {ISuperRouter} from "../../interfaces/ISuperRouter.sol";
import {AckAMBData, AMBExtraData, TransactionType, CallbackType, InitSingleVaultData, AMBMessage, ReturnSingleData} from "../../types/DataTypes.sol";
import "forge-std/console.sol";

/// @title TimelockForm Redeemer
/// @author Zeropoint Labs
contract FormStateRegistry is BaseStateRegistry, IFormStateRegistry {

    mapping(uint256 payloadId => uint256 superFormId) public payloadStore;

    /// TODO: Can this be spoofed?
    modifier onlyForm(uint256 superFormId) {
        (address form_, , ) = _getSuperForm(superFormId);
        if (msg.sender != form_) revert Error.NOT_FORM_KEEPER();
        _;
    }

    modifier onlyFormKeeper() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasFormStateRegistryRole(
                msg.sender
            )
        ) revert Error.NOT_FORM_KEEPER();
        _;
    }

    constructor(ISuperRegistry superRegistry_) BaseStateRegistry(superRegistry_) {}

    function receivePayload(
        uint256 payloadId,
        uint256 superFormId
    ) external onlyForm(superFormId) {
        payloadStore[payloadId] = superFormId;
    }

    function initPayload(uint256 payloadId, bytes memory ackExtraData) external onlyFormKeeper {
        (address form_, , ) = _getSuperForm(payloadStore[payloadId]);
        IERC4626Timelock form = IERC4626Timelock(form_);
        try form.processUnlock(payloadId) {
            delete payloadStore[payloadId];
        } catch {
            delete payloadStore[payloadId]; /// @dev If we want user to fully re-init withdraw
            InitSingleVaultData memory singleVaultData = form.unlockId(payloadId);
            (uint16 srcChainId, bytes memory returnMessage) = _constructSingleReturnData(singleVaultData); /// catch doesnt access singleVaultData
            _dispatchAcknowledgement(srcChainId, returnMessage, ackExtraData); /// NOTE: ackExtraData needs to be specified 'just in case' if this fails
        }
    }


    /// @notice TokenBank function for build message back to the source. In regular flow called after xChainWithdraw succeds.
    /// @dev Constructs return message in case of FAILURE to perform redemption of already unlocked assets
    function _constructSingleReturnData(
        InitSingleVaultData memory singleVaultData_
    ) internal view returns (uint16 srcChainId, bytes memory returnMessage) {
        (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
            singleVaultData_.txData
        );

        /// @notice Send Data to Source to issue superform positions.
        return (
            srcChainId,
            abi.encode(
                AMBMessage(
                    _packTxInfo(
                        uint120(TransactionType.WITHDRAW),
                        uint120(CallbackType.FAIL),
                        false,
                        0
                    ),
                    abi.encode(
                        ReturnSingleData(
                            _packReturnTxInfo(
                                1, /// @dev TODO: What status to return on fail?
                                srcChainId,
                                superRegistry.chainId(),
                                currentTotalTxs
                            ),
                            singleVaultData_.amount
                        )
                    )
                )
            )
        );
    }

    /// @notice In regular flow, BaseStateRegistry function for messaging back to the source
    /// @notice Use constructed earlier return message to send acknowledgment (msg) back to the source
    function _dispatchAcknowledgement(
        uint16 dstChainId_,
        bytes memory message_,
        bytes memory ackExtraData_ /// TODO: This is only accessible to CoreStateRegistry
    ) internal {
        AckAMBData memory ackData = abi.decode(ackExtraData_, (AckAMBData));
        uint8[] memory ambIds_ = ackData.ambIds;

        /// @dev atleast 2 AMBs are required
        if (ambIds_.length < 2) {
            revert Error.INVALID_AMB_IDS_LENGTH();
        }

        AMBExtraData memory d = abi.decode(ackData.extraData, (AMBExtraData));

        _dispatchPayload(
            ambIds_[0],
            dstChainId_,
            d.gasPerAMB[0],
            message_,
            d.extraDataPerAMB[0]
        );

        _dispatchProof(
            ambIds_,
            dstChainId_,
            d.gasPerAMB,
            message_,
            d.extraDataPerAMB
        );
    }
}
