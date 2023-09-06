// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import { Error } from "../utils/Error.sol";
import { AMBMessage } from "../types/DataTypes.sol";

/// @dev generates proof from AMB Message
library ProofLib {
    function computeProof(AMBMessage memory _message) internal pure returns (bytes32) {
        return keccak256(abi.encode(_message));
    }

    function computeProofBytes(AMBMessage memory _message) internal pure returns (bytes memory) {
        return abi.encode(keccak256(abi.encode(_message)));
    }

    function validateProofAMBs(uint8[] memory ambIds_) internal pure {
        uint256 len = ambIds_.length;

        for (uint8 i = 1; i < len;) {
            uint8 tempAmbId = ambIds_[i];

            if (tempAmbId == ambIds_[0]) {
                revert Error.INVALID_PROOF_BRIDGE_ID();
            }

            if (i - 1 > 0 && tempAmbId <= ambIds_[i - 1]) {
                revert Error.DUPLICATE_PROOF_BRIDGE_ID();
            }

            unchecked {
                ++i;
            }
        }
    }
}
