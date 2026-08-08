```
// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

interface IBridgeValidator {
    /**
     * @dev Validates cross-chain payload
     * @param payloadId ID of the payload being validated
     * @param token Address of the bridged token
     * @param amount Amount being bridged
     * @return true if payload is valid, false otherwise
     */
    function validatePayload(
        uint256 payloadId,
        address token,
        uint256 amount
    ) external returns (bool);
}