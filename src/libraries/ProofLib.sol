// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { AMBMessage } from "../types/DataTypes.sol";

/// @dev generates proof for amb message and bytes encoded message
library ProofLib {
    function computeProof(AMBMessage memory message_) internal pure returns (bytes32) {
        return keccak256(abi.encode(message_));
    }

    function computeProofBytes(AMBMessage memory message_) internal pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encode(message_)));
    }

    function computeProof(bytes memory message_) internal pure returns (bytes32) {
        return keccak256(message_);
    }

    function computeProofBytes(bytes memory message_) internal pure returns (bytes memory) {
        return abi.encode(keccak256(message_));
    }
}
