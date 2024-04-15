// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import "../../../utils/BaseSetup.sol";

import { StdCheats } from "forge-std/StdCheats.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

abstract contract MerkleReader is StdCheats, BaseSetup {
    using stdJson for string;

    string private basePathForRoot = "/test/fuzz/rewardsDistributor/target/jsGeneratedRoot";
    string private basePathForProof = "/test/fuzz/rewardsDistributor/target/jsTreeDump";

    string private prepend = ".values[";

    string private claimerQueryAppend = "].claimer";

    string private periodIdQueryAppend = "].periodId";

    string private rewardTokensQueryAppend = "].rewardTokens";

    string private amountsClaimedQueryAppend = "].amountsClaimed";

    string private chainIdQueryAppend = "].chainId";

    string private proofQueryAppend = "].proof";

    struct LocalVars {
        bytes encodedClaimer;
        bytes encodedPeriod;
        bytes encodedRewardTokens;
        bytes encodedAmountsClaimed;
        bytes encodedChainId;
        bytes encodedProof;
        address claimer;
        uint256 periodId;
        address[] rewardTokens;
        uint256[] amountsClaimed;
        uint256 chainId;
    }

    /// @dev read the merkle root and proof from js generated tree
    function _generateMerkleTree(
        uint256 periodId_,
        address claimer_,
        uint256 chainId_
    )
        internal
        view
        returns (bytes32 root, bytes32[] memory proofsForIndex)
    {
        string memory periodStr = Strings.toString(periodId_);
        string memory rootJson = vm.readFile(string.concat(vm.projectRoot(), basePathForRoot, periodStr, ".json"));
        bytes memory encodedRoot = vm.parseJson(rootJson, ".root");
        root = abi.decode(encodedRoot, (bytes32));
        if (claimer_ != address(0)) {
            LocalVars memory v;

            string memory proofJson = vm.readFile(string.concat(vm.projectRoot(), basePathForProof, periodStr, ".json"));

            /// get the total elements to find out the right proof
            bytes memory encodedValuesJson = vm.parseJson(proofJson, ".values[*]");
            string[] memory valuesArr = abi.decode(encodedValuesJson, (string[]));
            uint256 valuesArrLen = valuesArr.length;

            for (uint256 i; i < valuesArrLen; ++i) {
                v.encodedClaimer =
                    vm.parseJson(proofJson, string.concat(prepend, Strings.toString(i), claimerQueryAppend));
                v.encodedPeriod =
                    vm.parseJson(proofJson, string.concat(prepend, Strings.toString(i), periodIdQueryAppend));
                v.encodedRewardTokens =
                    vm.parseJson(proofJson, string.concat(prepend, Strings.toString(i), rewardTokensQueryAppend));
                v.encodedAmountsClaimed =
                    vm.parseJson(proofJson, string.concat(prepend, Strings.toString(i), amountsClaimedQueryAppend));
                v.encodedChainId =
                    vm.parseJson(proofJson, string.concat(prepend, Strings.toString(i), chainIdQueryAppend));

                v.claimer = abi.decode(v.encodedClaimer, (address));
                v.periodId = abi.decode(v.encodedPeriod, (uint256));
                v.rewardTokens = abi.decode(v.encodedRewardTokens, (address[]));
                v.amountsClaimed = abi.decode(v.encodedAmountsClaimed, (uint256[]));
                v.chainId = abi.decode(v.encodedChainId, (uint256));

                if (v.claimer == claimer_ && v.periodId == periodId_ && v.chainId == chainId_) {
                    v.encodedProof =
                        vm.parseJson(proofJson, string.concat(prepend, Strings.toString(i), proofQueryAppend));
                    proofsForIndex = abi.decode(v.encodedProof, (bytes32[]));
                    break;
                }
            }
        }
    }
}
