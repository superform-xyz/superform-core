// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

abstract contract MerkleReader is PRBTest, StdCheats {
    using stdJson for string;

    string private basePathForRoot = "/test/fuzz/rewardsDistributor/target/jsGeneratedRoot";
    string private basePathForProof = "/test/fuzz/rewardsDistributor/target/jsTreeDump";
    string private claimerQueryPrepend = ".values[";
    string private claimerQueryAppend = "].claimer";

    string private periodIdQueryPrepend = ".values[";
    string private periodIdQueryAppend = "].periodId";

    string private rewardTokensQueryPrepend = ".values[";
    string private rewardTokensQueryAppend = "].rewardTokens";

    string private amountsClaimedQueryPrepend = ".values[";
    string private amountsClaimedQueryAppend = "].amountsClaimed";

    string private chainIdQueryPrepend = ".values[";
    string private chainIdQueryAppend = "].chainId";

    string private proofQueryPrepend = ".values[";
    string private proofQueryAppend = "].proof";

    struct Value {
        address claimer;
        uint256 periodId;
    }

    /// @dev read the merkle root and proof from js generated tree
    function _generateMerkleTree(
        uint256 editionId_,
        address claimer_,
        uint256 periodId_
    )
        internal
        view
        returns (bytes32 root, bytes32[] memory proofsForIndex)
    {
        string memory editionStr = Strings.toString(editionId_);
        string memory rootJson = vm.readFile(string.concat(vm.projectRoot(), basePathForRoot, editionStr, ".json"));
        bytes memory encodedRoot = vm.parseJson(rootJson, ".root");
        root = abi.decode(encodedRoot, (bytes32));

        if (claimer_ != address(0)) {
            string memory proofJson =
                vm.readFile(string.concat(vm.projectRoot(), basePathForProof, editionStr, ".json"));

            /// get the total elements to find out the right proof
            bytes memory encodedValuesJson = vm.parseJson(proofJson, ".values[*]");
            string[] memory valuesArr = abi.decode(encodedValuesJson, (string[]));
            uint256 valuesArrLen = valuesArr.length;

            for (uint256 i; i < valuesArrLen; ++i) {
                bytes memory encodedUser =
                    vm.parseJson(proofJson, string.concat(claimerQueryPrepend, Strings.toString(i), claimerQueryAppend));
                bytes memory encodedPeriod = vm.parseJson(
                    proofJson, string.concat(periodIdQueryPrepend, Strings.toString(i), periodIdQueryAppend)
                );

                address claimer = abi.decode(encodedUser, (address));
                uint256 periodId = abi.decode(encodedTier, (uint256));

                if (claimer == claimer_ && periodId == periodId_) {
                    bytes memory encodedProof =
                        vm.parseJson(proofJson, string.concat(proofQueryPrepend, Strings.toString(i), proofQueryAppend));
                    proofsForIndex = abi.decode(encodedProof, (bytes32[]));
                    break;
                }
            }
        }
    }
}
