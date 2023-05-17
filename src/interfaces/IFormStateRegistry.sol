// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

/// @title IFormStateRegistry
/// @author ZeroPoint Labs
/// @notice Interface for Form State Registry
interface IFormStateRegistry {
    function receivePayload(
        uint256 payloadId,
        uint256 superFormId,
        address owner
    ) external;

    function finalizePayload(
        uint256 payloadId,
        bytes memory ackExtraData_
    ) external;
}
