// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ILiFi
/// @notice Interface containing useful structs when using LiFi as a bridge
/// @notice taken from LiFi contracts https://github.com/lifinance/contracts
interface ILiFi {
    struct BridgeData {
        bytes32 transactionId;
        string bridge;
        string integrator;
        address referrer;
        address sendingAssetId;
        address receiver;
        uint256 minAmount;
        uint256 destinationChainId;
        bool hasSourceSwaps;
        bool hasDestinationCall; // is there a destination call? we should disable this
    }
}
