// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { RewardsDistributor } from "src/RewardsDistributor.sol";
import { MerkleReader } from "test/utils/merkle/helper/MerkleReader.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { StdInvariant } from "forge-std/StdInvariant.sol";
import { RewardsDistributorStore } from "../stores/RewardsDistributorStore.sol";
import "forge-std/console.sol";

contract RewardsDistributorHandler is StdInvariant, MerkleReader {
    RewardsDistributorStore public store;

    /// rest of logic

    RewardsDistributor private rewards;

    mapping(uint256 => bool) private isPeriodSelected;
    mapping(address => bool) private isUserSelected;
    mapping(address => mapping(uint256 periodId => bool selected)) private isUserSelectedBatch;

    string path = "output.txt";

    uint256 totalSelectedUsers;
    uint256[] totalTestUsers;
    uint256 totalUSDCToDeposit;
    uint256 totalDAIToDeposit;
    address[][] private testUsers;
    address[30] private defaultUsers = [
        0x0000000000000000000000000000000000000001,
        0x0000000000000000000000000000000000000002,
        0x0000000000000000000000000000000000000003,
        0x0000000000000000000000000000000000000004,
        0x0000000000000000000000000000000000000005,
        0x0000000000000000000000000000000000000006,
        0x0000000000000000000000000000000000000007,
        0x0000000000000000000000000000000000000008,
        0x0000000000000000000000000000000000000009,
        0x0000000000000000000000000000000000000010,
        0x0000000000000000000000000000000000000011,
        0x0000000000000000000000000000000000000012,
        0x0000000000000000000000000000000000000013,
        0x0000000000000000000000000000000000000014,
        0x0000000000000000000000000000000000000015,
        0x0000000000000000000000000000000000000016,
        0x0000000000000000000000000000000000000017,
        0x0000000000000000000000000000000000000018,
        0x0000000000000000000000000000000000000019,
        0x0000000000000000000000000000000000000020,
        0x0000000000000000000000000000000000000021,
        0x0000000000000000000000000000000000000022,
        0x0000000000000000000000000000000000000023,
        0x0000000000000000000000000000000000000024,
        0x0000000000000000000000000000000000000025,
        0x0000000000000000000000000000000000000026,
        0x0000000000000000000000000000000000000027,
        0x0000000000000000000000000000000000000028,
        0x0000000000000000000000000000000000000029,
        0x0000000000000000000000000000000000000030
    ];

    constructor(
        uint64[] memory chainIds_,
        string[35] memory contractNames_,
        address[][] memory coreContracts,
        uint256[] memory forksArray,
        RewardsDistributorStore _rewardsDistributorStore
    ) {
        store = _rewardsDistributorStore;

        _initHandler(InitHandlerSetupVars(chainIds_, contractNames_, coreContracts, forksArray));

        vm.selectFork(FORKS[OP]);

        rewards = RewardsDistributor(getContract(OP, "RewardsDistributor"));

        vm.startPrank(deployer);

        for (uint256 i = 0; i < 3; i++) {
            bytes32 root;
            uint256 claimers;
            uint256 usdcToDeposit;
            uint256 daiToDeposit;
            (root, claimers, usdcToDeposit, daiToDeposit,,,) =
                _generateMerkleTree(MerkleReader.MerkleArgs(i, address(0), OP));

            rewards.setPeriodicRewards(root);

            totalTestUsers.push(claimers);
            totalUSDCToDeposit += usdcToDeposit;
            totalDAIToDeposit += daiToDeposit;
        }
        deal(USDC, address(rewards), totalUSDCToDeposit);
        deal(DAI, address(rewards), totalDAIToDeposit);
        /*
        0
        Total amount USDC: 5349
        Total amount DAI: 5070
        Number of claimers: 16
        1
        Total amount USDC: 4716
        Total amount DAI: 4678
        Number of claimers: 16
        2
        Total amount USDC: 4604
        Total amount DAI: 5463
        Number of claimers: 13
        sum USDC: 14669
        sum DAI: 15211
        */

        vm.stopPrank();
        address[][] memory testUsersMem = new address[][](3);

        /// @dev add max amount of users here
        for (uint256 i = 0; i < 3; i++) {
            address[] memory testUsersMem2 = new address[](totalTestUsers[i]);

            for (uint256 j = 0; j < totalTestUsers[i]; j++) {
                testUsersMem2[j] = defaultUsers[j];
            }
            testUsersMem[i] = testUsersMem2;
        }
        testUsers = testUsersMem;

        console.log("Handler setup done!");
    }

    function randomUserIndex(uint256 seed, uint256 index, uint256 periodId) internal view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(index, seed, tx.origin, blockhash(block.number - 1), block.timestamp))
        ) % totalTestUsers[periodId];
    }

    function randomPeriod(uint256 seed, uint256 index) internal view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(index, seed, tx.origin, blockhash(block.number - 1), block.timestamp))
        ) % 3;
    }

    function full_claim(uint256 seed) public {
        vm.selectFork(FORKS[OP]);
        vm.writeLine(path, string.concat("Normal Run id: ", Strings.toString(seed)));

        for (uint256 i; i < 100; i++) {
            uint256 periodId = randomPeriod(seed, i);

            if (isPeriodSelected[periodId]) {
                continue;
            } else {
                isPeriodSelected[periodId] = true;
                store.setTotalPeriodsSelected(store.totalPeriodsSelected() + 1);
                store.setTotalTestUsers(periodId, totalTestUsers[periodId]);

                for (uint256 j; j < 1000; j++) {
                    uint256 userIndex = randomUserIndex(seed, j, periodId);

                    address selectedUser = testUsers[periodId][userIndex];
                    if (isUserSelected[selectedUser]) {
                        continue;
                    } else {
                        // Mark the user as selected
                        isUserSelected[selectedUser] = true;

                        store.setTotalSelectedUsers(periodId, store.totalSelectedUsersPeriod(periodId) + 1);

                        // claim funds for that user

                        (,,,, bytes32[] memory proof_, address[] memory tokensToClaim, uint256[] memory amountsToClaim)
                        = _generateMerkleTree(MerkleReader.MerkleArgs(periodId, selectedUser, OP));

                        vm.prank(selectedUser);
                        rewards.claim(selectedUser, periodId, tokensToClaim, amountsToClaim, proof_);
                    }
                    if (store.totalSelectedUsersPeriod(periodId) == totalTestUsers[periodId]) {
                        /// period fully claimed
                        // clear the user selected
                        for (uint256 k; k < totalTestUsers[periodId]; k++) {
                            isUserSelected[testUsers[periodId][k]] = false;
                        }

                        break;
                    }
                }

                if (store.totalPeriodsSelected() == 3) {
                    /// fully claimed

                    uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(address(rewards));
                    uint256 daiBalanceAfter = IERC20(DAI).balanceOf(address(rewards));

                    store.setUSDCBalanceAfter(usdcBalanceAfter);
                    store.setDAIBalanceAfter(daiBalanceAfter);

                    break;
                }
            }
        }
    }

    function full_batch_claim(uint256 seed) public {
        vm.selectFork(FORKS[OP]);
        vm.writeLine(path, string.concat("Batch Run id: ", Strings.toString(seed)));

        // determine highest number of test users & period
        uint256 highestNumberOfTestUsers = 0;
        uint256 periodWithHighestNumberOfTestUsers = 0;
        for (uint256 k; k < 3; k++) {
            if (totalTestUsers[k] > highestNumberOfTestUsers) {
                highestNumberOfTestUsers = totalTestUsers[k];
                periodWithHighestNumberOfTestUsers = k;
            }
            store.setTotalTestUsers(k, totalTestUsers[k]);
        }

        vm.writeLine(path, string.concat("highestNumberOfTestUsers: ", Strings.toString(highestNumberOfTestUsers)));

        vm.writeLine(
            path,
            string.concat("periodWithHighestNumberOfTestUsers: ", Strings.toString(periodWithHighestNumberOfTestUsers))
        );

        for (uint256 j; j < 1000; j++) {
            // select a user index
            uint256 userIndex = randomUserIndex(seed, j, periodWithHighestNumberOfTestUsers);

            // find the periods in which the selected user index is  lower to the number of test users of the
            // period
            uint256[] memory periodsWithUserPresentTemp = new uint256[](3);
            uint256 nPeriodsForUser;

            for (uint256 k; k < 3; k++) {
                if (userIndex < totalTestUsers[k]) {
                    periodsWithUserPresentTemp[nPeriodsForUser] = k;
                    ++nPeriodsForUser;
                }
            }
            assert(nPeriodsForUser > 0);

            uint256[] memory periodsWithUserPresent = new uint256[](nPeriodsForUser);

            for (uint256 k; k < nPeriodsForUser; k++) {
                periodsWithUserPresent[k] = periodsWithUserPresentTemp[k];
            }

            bytes32[][] memory batchProofs = new bytes32[][](nPeriodsForUser);
            address[][] memory batchTokensToClaim = new address[][](nPeriodsForUser);
            uint256[][] memory batchAmountsToClaim = new uint256[][](nPeriodsForUser);

            // address will be the same among periodsWithUserPresent
            address selectedUser = testUsers[periodsWithUserPresent[0]][userIndex];
            if (isUserSelected[selectedUser]) {
                continue;
            } else {
                vm.writeLine(path, string.concat("selectedUser: ", Strings.toHexString(selectedUser)));
                vm.writeLine(path, string.concat("nPeriodsForUser: ", Strings.toString(nPeriodsForUser)));

                // Mark the user as selected
                isUserSelected[selectedUser] = true;
                for (uint256 k; k < nPeriodsForUser; k++) {
                    store.setTotalSelectedUsers(k, store.totalSelectedUsersPeriod(k) + 1);

                    // generate batch proofs for user

                    (,,,, bytes32[] memory proof_, address[] memory tokensToClaim, uint256[] memory amountsToClaim) =
                        _generateMerkleTree(MerkleReader.MerkleArgs(k, selectedUser, OP));

                    batchProofs[k] = proof_;
                    batchTokensToClaim[k] = tokensToClaim;
                    batchAmountsToClaim[k] = amountsToClaim;
                }

                vm.prank(selectedUser);
                rewards.batchClaim(
                    selectedUser, periodsWithUserPresent, batchTokensToClaim, batchAmountsToClaim, batchProofs
                );
            }

            /// when a user is selected, all the periods for it are fully claimed
            /// condition ends when all users in all periods are done
            bool allUsersAllPeriodsDone = true;
            for (uint256 k; k < 3; k++) {
                if (store.totalSelectedUsersPeriod(k) != totalTestUsers[k]) {
                    allUsersAllPeriodsDone = false;
                }
            }
            if (allUsersAllPeriodsDone) {
                uint256 usdcBalanceAfter = IERC20(USDC).balanceOf(address(rewards));
                uint256 daiBalanceAfter = IERC20(DAI).balanceOf(address(rewards));

                store.setUSDCBalanceAfter(usdcBalanceAfter);
                store.setDAIBalanceAfter(daiBalanceAfter);
                break;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                    INTERNAL HANDLER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    struct InitHandlerSetupVars {
        uint64[] chainIds;
        string[35] contractNames;
        address[][] coreContracts;
        uint256[] forksArray;
    }

    function _initHandler(InitHandlerSetupVars memory vars) internal {
        mapping(uint64 => uint256) storage forks = FORKS;

        for (uint256 i = 0; i < vars.chainIds.length; ++i) {
            forks[vars.chainIds[i]] = vars.forksArray[i];
        }
        _preDeploymentSetup(false, true);

        for (uint256 i = 0; i < vars.chainIds.length; ++i) {
            for (uint256 j = 0; j < vars.contractNames.length; ++j) {
                contracts[vars.chainIds[i]][bytes32(bytes(vars.contractNames[j]))] = vars.coreContracts[i][j];
            }
        }
    }
}
