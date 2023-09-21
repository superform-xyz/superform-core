// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { ProofLib } from "src/libraries/ProofLib.sol";
import { AMBMessage } from "src/types/DataTypes.sol";

contract ProofLibUser {
    function computeProof(AMBMessage memory message_) external pure returns (bytes32) {
        return ProofLib.computeProof(message_);
    }

    function computeProofBytes(AMBMessage memory message_) external pure returns (bytes memory) {
        return ProofLib.computeProofBytes(message_);
    }

    function computeProof(bytes memory message_) external pure returns (bytes32) {
        return ProofLib.computeProof(message_);
    }

    function computeProofBytes(bytes memory message_) external pure returns (bytes memory) {
        return ProofLib.computeProofBytes(message_);
    }
}

contract ProofLibTest is Test {
    ProofLibUser proofLib;

    function setUp() external {
        proofLib = new ProofLibUser();
    }

    function test_castLiqRequestToArray() external {
        AMBMessage memory message = AMBMessage(1, "");

        bytes memory msgBytes = abi.encode(message);

        assertEq(keccak256(abi.encode(message)), proofLib.computeProof(message));
        assertEq(abi.encode(keccak256(abi.encode(message))), proofLib.computeProofBytes(message));
        assertEq(keccak256(msgBytes), proofLib.computeProof(msgBytes));
        assertEq(abi.encode(keccak256(msgBytes)), proofLib.computeProofBytes(msgBytes));
    }
}
