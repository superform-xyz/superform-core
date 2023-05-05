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
contract FormStateRegistry is IFormStateRegistry {

    ISuperRegistry public superRegistry;

    mapping(uint256 payloadId => uint256 superFormId) public payloadStore;

    /// TODO: Can this be spoofed?
    modifier onlyForm(uint256 superFormId) {
        (address form_, , ) = _getSuperForm(superFormId);
        if (msg.sender != form_) revert Error.NOT_FORM_KEEPER();
        _;
    }

    modifier onlyFormKeeper() {
        if (
            !ISuperRBAC(superRegistry.superRBAC()).hasFormStateRegistryRole(msg.sender)
        ) revert Error.NOT_FORM_KEEPER();
        _;
    }

    constructor(address superRegistry_) {
        superRegistry = ISuperRegistry(superRegistry_);
    }

    function receivePayload(
        uint256 payloadId,
        uint256 superFormId
    ) external onlyForm(superFormId) {
        payloadStore[payloadId] = superFormId;
    }

    function initPayload(uint256 payloadId) external onlyFormKeeper {
        (address form_, , ) = _getSuperForm(payloadStore[payloadId]);
        IERC4626Timelock(form_).processUnlock(payloadId);
        delete payloadStore[payloadId];
        /// @dev why do we need to message back?
    }

    /// NOTE: To enable FormStateRegistry messaging functionality, below functions needs to be adapted
    /// NOTE: Those functions come from both BaseStateRegistry and TokenBank where they are used with different design in mind

    /// @notice TokenBank function for build message back to the source. Called after xChainWithdraw succeds.
    // function _constructSingleReturnData(
    //     InitSingleVaultData memory singleVaultData_,
    //     uint16 status
    // ) internal view returns (uint16, bytes memory) {
    //     (, uint16 srcChainId, uint80 currentTotalTxs) = _decodeTxData(
    //         singleVaultData_.txData
    //     );

    //     /// @notice Send Data to Source to issue superform positions.
    //     return (
    //         srcChainId,
    //         abi.encode(
    //             AMBMessage(
    //                 _packTxInfo(uint120(TransactionType.WITHDRAW), uint120(CallbackType.RETURN), false, 0),
    //                 abi.encode(
    //                     ReturnSingleData(
    //                         _packReturnTxInfo(
    //                             status,
    //                             srcChainId,
    //                             superRegistry.chainId(),
    //                             currentTotalTxs
    //                         ),
    //                         singleVaultData_.amount
    //                     )
    //                 )
    //             )
    //         )
    //     );
    // }

    /// @notice BaseStateRegistry function for messaging back to source
    // function _dispatchAcknowledgement(
    //     uint16 dstChainId_,
    //     bytes memory message_,
    //     bytes memory ackExtraData_
    // ) internal {
    //     AckAMBData memory ackData = abi.decode(ackExtraData_, (AckAMBData));
    //     uint8[] memory ambIds_ = ackData.ambIds;

    //     /// @dev atleast 2 AMBs are required
    //     if (ambIds_.length < 2) {
    //         revert Error.INVALID_AMB_IDS_LENGTH();
    //     }

    //     AMBExtraData memory d = abi.decode(ackData.extraData, (AMBExtraData));

    //     _dispatchPayload(
    //         ambIds_[0],
    //         dstChainId_,
    //         d.gasPerAMB[0],
    //         message_,
    //         d.extraDataPerAMB[0]
    //     );

    //     _dispatchProof(
    //         ambIds_,
    //         dstChainId_,
    //         d.gasPerAMB,
    //         message_,
    //         d.extraDataPerAMB
    //     );
    // }

}
