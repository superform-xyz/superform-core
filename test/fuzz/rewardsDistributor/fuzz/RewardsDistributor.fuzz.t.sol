// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import "../../../utils/BaseSetup.sol";

import { RewardsDistributor } from "src/RewardsDistributor.sol";
import { MerkleReader } from "../helper/MerkleReader.sol";

contract RewardsDistributorFuzzTest is MerkleReader, BaseSetup {
    uint256[] public claimedSeeds;

    uint256 seedState;
    bool limitRchd;

    RewardsDistributor public rewards;

    function setUp() public virtual {
        vm.selectFork(FORKS[OP]);
        vm.startPrank(deployer);

        rewards = new RewardsDistributor(getContract(OP, "SuperRegistry"));

        (bytes32 root,) = _generateMerkleTree(0, address(0));

        rewards.setPeriodicRewards(root);

        vm.stopPrank();
    }
    /*
    function testFuzz_claim(uint256 seed) public {
        if (seed > 29) {
            if (!limitRchd) {
                seed = ++seedState;

                if (seed >= 29) {
                    limitRchd = !limitRchd;
                }
            } else {
                seed = --seedState;

                if (seed <= 1) {
                    limitRchd = !limitRchd;
                }
            }
        }

        address[30] memory users = [
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

        for (uint256 i; i < seed; i++) {
            uint256 tierId;
            if (i < 1) {
                tierId = 0;
            } else if (i < 2) {
                tierId = 1;
            } else if (i < 3) {
                tierId = 2;
            } else if (i < 5) {
                tierId = 3;
            } else if (i < 10) {
                tierId = 4;
            } else if (i < 20) {
                tierId = 5;
            } else {
                tierId = 6;
            }

            _assertAndClaimLite(users[i], tierId, forger, _contains(i));
            _checkAndForge(tierId);

            claimedSeeds.push(i);
        }
    }

    function _contains(uint256 seed) internal view returns (bool) {
        for (uint256 i; i < claimedSeeds.length; i++) {
            if (claimedSeeds[i] == seed) {
                return true;
            }
        }

        return false;
    }

    function _checkAndForge(uint256 tierId) internal {
        if (drop.balanceOf(forger, tierId) > 4) {
            vm.prank(forger);
            drop.forge(tierId);
        }
    }

    function _assertAndClaimLite(address user, uint256 claimedTierId, address transferTo, bool expectRevert) internal {
        (, bytes32[] memory proof) = _generateMerkleTree(3, user, claimedTierId);

        vm.warp(1);

        if (!expectRevert) {
            uint256 supplyClaimed = drop.supplyClaimedByWallet(claimedTierId, user);
            assertEq(supplyClaimed, 0);
        }

        (uint256 availableToMintBefore, uint256 supplyBefore) = drop.editionTiersSupply(0, claimedTierId);

        if (expectRevert) {
            vm.expectRevert(ISuperFrens.INVALID_CLAIM.selector);
        }

        vm.prank(user);
        drop.claim(user, 0, claimedTierId, proof);
        (uint256 availableToMintAfter, uint256 supplyAfter) = drop.editionTiersSupply(0, claimedTierId);

        if (!expectRevert) {
            assertEq(supplyAfter, supplyBefore + 1);
            assertEq(availableToMintAfter, availableToMintBefore - 1);
            assertEq(drop.balanceOf(user, claimedTierId), 1);
            assertEq(drop.supplyClaimedByWallet(claimedTierId, user), 1);

            if (transferTo != address(0)) {
                vm.prank(user);
                drop.safeTransferFrom(user, transferTo, claimedTierId, 1, "");
            }
        }
    }
    */
}
