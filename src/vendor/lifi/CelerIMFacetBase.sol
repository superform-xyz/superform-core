// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { ILiFi } from "./ILiFi.sol";
import { LibSwap } from "./LibSwap.sol";
import { MsgDataTypes } from "./celer-network/MsgDataTypes.sol";

interface CelerIM {
    /// @param maxSlippage The max slippage accepted, given as percentage in point (pip).
    /// @param nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
    /// @param callTo The address of the contract to be called at destination.
    /// @param callData The encoded calldata with below data
    ///                 bytes32 transactionId,
    ///                 LibSwap.SwapData[] memory swapData,
    ///                 address receiver,
    ///                 address refundAddress
    /// @param messageBusFee The fee to be paid to CBridge message bus for relaying the message
    /// @param bridgeType Defines the bridge operation type (must be one of the values of CBridge library
    /// MsgDataTypes.BridgeSendType)
    struct CelerIMData {
        uint32 maxSlippage;
        uint64 nonce;
        bytes callTo;
        bytes callData;
        uint256 messageBusFee;
        MsgDataTypes.BridgeSendType bridgeType;
    }
}

/// @title CelerIM Facet Base
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging tokens and data through CBridge
/// @notice Used to differentiate between contract instances for mutable and immutable diamond as these cannot be shared
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts and stripped down to needs
/// @custom:version 2.0.0
abstract contract CelerIMFacetBase {
    /// External Methods ///

    /// @notice Bridges tokens via CBridge
    /// @param _bridgeData The core information needed for bridging
    /// @param _celerIMData Data specific to CelerIM
    function startBridgeTokensViaCelerIM(
        ILiFi.BridgeData memory _bridgeData,
        CelerIM.CelerIMData calldata _celerIMData
    )
        external
        payable
    { }

    /// @notice Performs a swap before bridging via CBridge
    /// @param _bridgeData The core information needed for bridging
    /// @param _swapData An array of swap related data for performing swaps before bridging
    /// @param _celerIMData Data specific to CelerIM
    function swapAndStartBridgeTokensViaCelerIM(
        ILiFi.BridgeData memory _bridgeData,
        LibSwap.SwapData[] calldata _swapData,
        CelerIM.CelerIMData calldata _celerIMData
    )
        external
        payable
    { }
}
