// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { RewardsDistributor } from "src/RewardsDistributor.sol";
import { IRewardsDistributor } from "src/interfaces/IRewardsDistributor.sol";
import { MerkleReader } from "test/utils/merkle/helper/MerkleReader.sol";
import { SuperRBAC } from "src/settings/SuperRBAC.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract RewardsDistributorTests is MerkleReader {
    RewardsDistributor private rewards;

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

    function setUp() public virtual override {
        super.setUp();
        vm.selectFork(FORKS[OP]);

        rewards = RewardsDistributor(getContract(OP, "RewardsDistributor"));

        vm.startPrank(deployer);

        address[][] memory testUsersMem = new address[][](3);
        uint256 claimers;

        /// @dev add max amount of users here
        for (uint256 i = 0; i < 3; i++) {
            (, claimers,,,,,) = _generateMerkleTree(MerkleReader.MerkleArgs(i, address(0), OP));
            totalTestUsers.push(claimers);

            address[] memory testUsersMem2 = new address[](claimers);

            for (uint256 j = 0; j < claimers; j++) {
                testUsersMem2[j] = defaultUsers[j];
            }
            testUsersMem[i] = testUsersMem2;
        }
        testUsers = testUsersMem;

        /// @dev add root 0 by default
        bytes32 root;
        uint256 usdcToDeposit;
        uint256 daiToDeposit;
        (root,, usdcToDeposit, daiToDeposit,,,) = _generateMerkleTree(MerkleReader.MerkleArgs(0, address(0), OP));

        bytes32 emptyRoot;

        vm.expectRevert(IRewardsDistributor.INVALID_MERKLE_ROOT.selector);
        rewards.setPeriodicRewards(emptyRoot);

        /// @dev setting root for period 0 only
        rewards.setPeriodicRewards(root);
        totalUSDCToDeposit += usdcToDeposit;
        totalDAIToDeposit += daiToDeposit;

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
    }

    function test_claim_invalidReceiver() public {
        address user = testUsers[0][0];

        (,,,, bytes32[] memory proof_, address[] memory tokensToClaim, uint256[] memory amountsToClaim) =
            _generateMerkleTree(MerkleReader.MerkleArgs(0, user, OP));

        vm.expectRevert(IRewardsDistributor.INVALID_RECEIVER.selector);
        rewards.claim(address(0), 0, tokensToClaim, amountsToClaim, proof_);
    }

    function test_claim_zeroarrlen() public {
        address user = testUsers[0][0];
        address[] memory tokensToClaim;
        (,,,, bytes32[] memory proof_,, uint256[] memory amountsToClaim) =
            _generateMerkleTree(MerkleReader.MerkleArgs(0, user, OP));

        vm.expectRevert(IRewardsDistributor.ZERO_ARR_LENGTH.selector);
        rewards.claim(user, 0, tokensToClaim, amountsToClaim, proof_);
    }

    function test_claim_invalidReqTokens() public {
        address user = testUsers[0][0];
        address[] memory tokensToClaim = new address[](10);
        (,,,, bytes32[] memory proof_,, uint256[] memory amountsToClaim) =
            _generateMerkleTree(MerkleReader.MerkleArgs(0, user, OP));

        vm.expectRevert(IRewardsDistributor.INVALID_REQ_TOKENS_AMOUNTS.selector);
        rewards.claim(user, 0, tokensToClaim, amountsToClaim, proof_);
    }

    function test_claim_merkleRootNotSet() public {
        address user = testUsers[1][0];
        (,,,, bytes32[] memory proof_, address[] memory tokensToClaim, uint256[] memory amountsToClaim) =
            _generateMerkleTree(MerkleReader.MerkleArgs(1, user, OP));
        vm.expectRevert(IRewardsDistributor.MERKLE_ROOT_NOT_SET.selector);
        rewards.claim(user, 1, tokensToClaim, amountsToClaim, proof_);
    }

    function test_claim_claimAndAlreadyClaimed() public {
        uint256 periodId = 0;
        address user = testUsers[periodId][0];
        (,,,, bytes32[] memory proof_, address[] memory tokensToClaim, uint256[] memory amountsToClaim) =
            _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

        vm.prank(user);
        rewards.claim(user, periodId, tokensToClaim, amountsToClaim, proof_);

        vm.expectRevert(IRewardsDistributor.ALREADY_CLAIMED.selector);
        vm.prank(user);
        rewards.claim(user, periodId, tokensToClaim, amountsToClaim, proof_);
    }

    function test_batchclaim_invalidReceiver() public {
        _addRoot();
        // common user
        address user = testUsers[0][1];

        uint256[] memory periodIds = new uint256[](2);
        periodIds[0] = 0;
        periodIds[1] = 1;

        bytes32[][] memory proofs = new bytes32[][](2);

        address[][] memory tokensToClaim = new address[][](2);

        uint256[][] memory amountsToClaim = new uint256[][](2);
        for (uint256 periodId = 0; periodId < 2; periodId++) {
            (,,,, bytes32[] memory proof_, address[] memory tokensToClaim_, uint256[] memory amountsToClaim_) =
                _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

            proofs[periodId] = proof_;
            tokensToClaim[periodId] = tokensToClaim_;
            amountsToClaim[periodId] = amountsToClaim_;
        }

        vm.expectRevert(IRewardsDistributor.INVALID_RECEIVER.selector);
        rewards.batchClaim(address(0), periodIds, tokensToClaim, amountsToClaim, proofs);
    }

    function test_batchclaim_noPeriods() public {
        _addRoot();
        // common user
        address user = testUsers[0][1];

        uint256[] memory periodIds;

        bytes32[][] memory proofs = new bytes32[][](2);

        address[][] memory tokensToClaim = new address[][](2);

        uint256[][] memory amountsToClaim = new uint256[][](2);
        for (uint256 periodId = 0; periodId < 2; periodId++) {
            (,,,, bytes32[] memory proof_, address[] memory tokensToClaim_, uint256[] memory amountsToClaim_) =
                _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

            proofs[periodId] = proof_;
            tokensToClaim[periodId] = tokensToClaim_;
            amountsToClaim[periodId] = amountsToClaim_;
        }

        vm.expectRevert(IRewardsDistributor.ZERO_ARR_LENGTH.selector);
        rewards.batchClaim(user, periodIds, tokensToClaim, amountsToClaim, proofs);
    }

    function test_batchclaim_invalidArraysLen() public {
        _addRoot();
        // common user
        address user = testUsers[0][1];

        uint256[] memory periodIds = new uint256[](2);
        periodIds[0] = 0;
        periodIds[1] = 1;

        bytes32[][] memory proofs = new bytes32[][](2);

        address[][] memory tokensToClaim = new address[][](3);

        uint256[][] memory amountsToClaim = new uint256[][](2);
        for (uint256 periodId = 0; periodId < 2; periodId++) {
            (,,,, bytes32[] memory proof_, address[] memory tokensToClaim_, uint256[] memory amountsToClaim_) =
                _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

            proofs[periodId] = proof_;
            tokensToClaim[periodId] = tokensToClaim_;
            amountsToClaim[periodId] = amountsToClaim_;
        }

        vm.expectRevert(IRewardsDistributor.INVALID_BATCH_REQ.selector);
        rewards.batchClaim(user, periodIds, tokensToClaim, amountsToClaim, proofs);
    }

    function test_batchclaim_noTokensToClaimInAPeriod() public {
        _addRoot();
        // common user
        address user = testUsers[0][1];

        uint256[] memory periodIds = new uint256[](2);
        periodIds[0] = 0;
        periodIds[1] = 1;

        bytes32[][] memory proofs = new bytes32[][](2);

        address[][] memory tokensToClaim = new address[][](2);

        uint256[][] memory amountsToClaim = new uint256[][](2);
        for (uint256 periodId = 0; periodId < 2; periodId++) {
            (,,,, bytes32[] memory proof_, address[] memory tokensToClaim_, uint256[] memory amountsToClaim_) =
                _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

            proofs[periodId] = proof_;
            tokensToClaim[periodId] = tokensToClaim_;
            if (periodId == 0) {
                tokensToClaim_ = new address[](0);
                tokensToClaim[periodId] = tokensToClaim_;
            }
            amountsToClaim[periodId] = amountsToClaim_;
        }

        vm.expectRevert(IRewardsDistributor.ZERO_ARR_LENGTH.selector);
        rewards.batchClaim(user, periodIds, tokensToClaim, amountsToClaim, proofs);
    }

    function test_batchclaim_invalidArraysLenInAPeriod() public {
        _addRoot();
        // common user
        address user = testUsers[0][1];

        uint256[] memory periodIds = new uint256[](2);
        periodIds[0] = 0;
        periodIds[1] = 1;

        bytes32[][] memory proofs = new bytes32[][](2);

        address[][] memory tokensToClaim = new address[][](2);

        uint256[][] memory amountsToClaim = new uint256[][](2);
        for (uint256 periodId = 0; periodId < 2; periodId++) {
            (,,,, bytes32[] memory proof_, address[] memory tokensToClaim_,) =
                _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

            proofs[periodId] = proof_;
            tokensToClaim[periodId] = tokensToClaim_;

            amountsToClaim[periodId] = new uint256[](10);
        }

        vm.expectRevert(IRewardsDistributor.INVALID_BATCH_REQ_TOKENS_AMOUNTS.selector);
        rewards.batchClaim(user, periodIds, tokensToClaim, amountsToClaim, proofs);
    }

    function test_batchclaim_claimAndAlreadyClaimed() public {
        _addRoot();
        // common user
        address user = testUsers[0][1];

        uint256[] memory periodIds = new uint256[](2);
        periodIds[0] = 0;
        periodIds[1] = 1;

        bytes32[][] memory proofs = new bytes32[][](2);

        address[][] memory tokensToClaim = new address[][](2);

        uint256[][] memory amountsToClaim = new uint256[][](2);
        for (uint256 periodId = 0; periodId < 2; periodId++) {
            (,,,, bytes32[] memory proof_, address[] memory tokensToClaim_, uint256[] memory amountsToClaim_) =
                _generateMerkleTree(MerkleReader.MerkleArgs(periodId, user, OP));

            proofs[periodId] = proof_;
            tokensToClaim[periodId] = tokensToClaim_;
            amountsToClaim[periodId] = amountsToClaim_;
        }

        vm.prank(user);
        rewards.batchClaim(user, periodIds, tokensToClaim, amountsToClaim, proofs);

        vm.expectRevert(IRewardsDistributor.ALREADY_CLAIMED.selector);
        vm.prank(user);
        rewards.batchClaim(user, periodIds, tokensToClaim, amountsToClaim, proofs);
    }

    function _addRoot() internal {
        bytes32 root;
        uint256 usdcToDeposit;
        uint256 daiToDeposit;
        uint256 periodId = rewards.currentPeriodId();
        (root,, usdcToDeposit, daiToDeposit,,,) = _generateMerkleTree(MerkleReader.MerkleArgs(periodId, address(0), OP));

        vm.startPrank(deployer);
        rewards.setPeriodicRewards(root);
        totalUSDCToDeposit += usdcToDeposit;
        totalDAIToDeposit += daiToDeposit;

        deal(USDC, address(rewards), totalUSDCToDeposit);
        deal(DAI, address(rewards), totalDAIToDeposit);
        vm.stopPrank();
    }
}
