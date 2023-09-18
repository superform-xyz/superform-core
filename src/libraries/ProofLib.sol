// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import { AMBMessage } from "../types/DataTypes.sol";

/// @dev generates proof for amb message and bytes encoded message
library ProofLib {
    function computeProof(AMBMessage memory _message) internal pure returns (bytes32) {
        return keccak256(abi.encode(_message));
    }

    function computeProofBytes(AMBMessage memory _message) internal pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encode(_message)));
    }

    function computeProof(bytes memory _message) internal pure returns (bytes32) {
        return keccak256(_message);
    }

    function computeProofBytes(bytes memory _message) internal pure returns (bytes memory) {
        return abi.encode(keccak256(_message));
    }
}
