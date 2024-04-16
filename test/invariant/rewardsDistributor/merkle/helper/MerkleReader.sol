// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "forge-std/StdJson.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../../../utils/BaseSetup.sol";

abstract contract MerkleReader is StdCheats, BaseSetup {
    using stdJson for string;

    string private basePathForRoot = "/test/invariant/rewardsDistributor/merkle/target/jsGeneratedRoot";
    string private basePathForTreeDump = "/test/invariant/rewardsDistributor/merkle/target/jsTreeDump";

    string private prepend = ".values[";

    string private claimerQueryAppend = "].claimer";

    string private periodIdQueryAppend = "].periodId";

    string private rewardTokensQueryAppend = "].rewardTokens";

    string private amountsClaimedQueryAppend = "].amountsClaimed";

    string private chainIdQueryAppend = "].chainId";

    string private proofQueryAppend = "].proof";

    address USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    address[] tokenTypes = [USDC, DAI];

    struct LocalVars {
        string rootJson;
        bytes encodedRoot;
        string treeJson;
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

    struct MerkleArgs {
        uint256 periodId_;
        address claimer_;
        uint256 chainId_;
    }

    /// @dev read the merkle root and proof from js generated tree
    function _generateMerkleTree(MerkleArgs memory a)
        internal
        view
        returns (
            bytes32 root,
            uint256 claimers,
            uint256 totalUSDCValue,
            uint256 totalDAIValue,
            bytes32[] memory proofsForIndex,
            address[] memory tokensForIndex,
            uint256[] memory amountsForIndex
        )
    {
        LocalVars memory v;

        v.rootJson =
            vm.readFile(string.concat(vm.projectRoot(), basePathForRoot, Strings.toString(a.periodId_), ".json"));
        v.encodedRoot = vm.parseJson(v.rootJson, ".root");
        root = abi.decode(v.encodedRoot, (bytes32));

        v.treeJson =
            vm.readFile(string.concat(vm.projectRoot(), basePathForTreeDump, Strings.toString(a.periodId_), ".json"));

        /// get the total elements to find out the right proof
        bytes memory encodedValuesJson = vm.parseJson(v.treeJson, ".values[*]");
        string[] memory valuesArr = abi.decode(encodedValuesJson, (string[]));
        claimers = valuesArr.length;
        for (uint256 i; i < claimers; ++i) {
            v.encodedClaimer = vm.parseJson(v.treeJson, string.concat(prepend, Strings.toString(i), claimerQueryAppend));
            v.encodedPeriod = vm.parseJson(v.treeJson, string.concat(prepend, Strings.toString(i), periodIdQueryAppend));
            v.encodedRewardTokens =
                vm.parseJson(v.treeJson, string.concat(prepend, Strings.toString(i), rewardTokensQueryAppend));
            v.encodedAmountsClaimed =
                vm.parseJson(v.treeJson, string.concat(prepend, Strings.toString(i), amountsClaimedQueryAppend));
            v.encodedChainId = vm.parseJson(v.treeJson, string.concat(prepend, Strings.toString(i), chainIdQueryAppend));

            v.claimer = abi.decode(v.encodedClaimer, (address));
            v.periodId = abi.decode(v.encodedPeriod, (uint256));
            v.rewardTokens = abi.decode(v.encodedRewardTokens, (address[]));
            v.amountsClaimed = abi.decode(v.encodedAmountsClaimed, (uint256[]));
            v.chainId = abi.decode(v.encodedChainId, (uint256));

            for (uint256 j; j < v.rewardTokens.length; ++j) {
                if (v.rewardTokens[j] == tokenTypes[0]) {
                    totalUSDCValue += v.amountsClaimed[j];
                } else if (v.rewardTokens[j] == tokenTypes[1]) {
                    totalDAIValue += v.amountsClaimed[j];
                }
            }

            if (
                a.claimer_ != address(0) && v.claimer == a.claimer_ && v.periodId == a.periodId_
                    && v.chainId == a.chainId_
            ) {
                v.encodedProof = vm.parseJson(v.treeJson, string.concat(prepend, Strings.toString(i), proofQueryAppend));
                proofsForIndex = abi.decode(v.encodedProof, (bytes32[]));

                tokensForIndex = v.rewardTokens;
                amountsForIndex = v.amountsClaimed;
                break;
            }
        }
    }
}
