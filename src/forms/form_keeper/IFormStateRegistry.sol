// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

interface IFormStateRegistry {
    
        function receivePayload(uint256 payloadId, uint256 superFormId) external;
    
        function initPayload(uint256 payloadId) external;
}