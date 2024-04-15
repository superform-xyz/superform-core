// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import { RewardsDistributor } from "src/RewardsDistributor.sol";
import { MerkleReader } from "../merkle/helper/MerkleReader.sol";
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

    mapping(address => bool) private isUserSelected;

    address USDC = 0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85;
    address DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
    bytes32 root;
    uint256 totalSelectedUsers;
    uint256 totalTestUsers;
    uint256 totalUSDCToDeposit;
    uint256 totalDAIToDeposit;
    address[] private testUsers;
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
        string[31] memory contractNames_,
        address[][] memory coreContracts,
        uint256[] memory forksArray,
        RewardsDistributorStore _rewardsDistributorStore
    ) {
        store = _rewardsDistributorStore;

        _initHandler(InitHandlerSetupVars(chainIds_, contractNames_, coreContracts, forksArray));

        vm.selectFork(FORKS[OP]);
        rewards = RewardsDistributor(getContract(OP, "RewardsDistributor"));
        vm.startPrank(deployer);

        (root, totalTestUsers, totalUSDCToDeposit, totalDAIToDeposit,,,) =
            _generateMerkleTree(MerkleReader.MerkleArgs("1", 0, address(0), OP));
        rewards.setPeriodicRewards(root);
        vm.stopPrank();

        /// high USDC user
        deal(USDC, address(rewards), totalUSDCToDeposit);

        /// high DAI user
        deal(DAI, address(rewards), totalDAIToDeposit);

        /// @dev add max amount of users here
        for (uint256 i; i < totalTestUsers; i++) {
            testUsers.push(defaultUsers[i]);
        }
        console.log("Handler setup done!");
    }

    function random(uint256 seed, uint256 index) internal view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(index, seed, tx.origin, blockhash(block.number - 1), block.timestamp))
        ) % totalTestUsers;
    }

    function full_claim(uint256 seed) public {
        string memory path = "output.txt";
        vm.selectFork(FORKS[OP]);

        vm.writeLine(path, string.concat("Run id: ", Strings.toString(seed)));
        store.setTotalTestUsers(totalTestUsers);

        for (uint256 i; i < 100; i++) {
            uint256 randomUserIndex = random(seed, i);

            address selectedUser = testUsers[randomUserIndex];
            if (isUserSelected[selectedUser]) {
                continue;
            } else {
                // Mark the user as selected
                isUserSelected[selectedUser] = true;

                store.setTotalSelectedUsers(store.totalSelectedUsers() + 1);

                // claim funds for that user

                (,,,, bytes32[] memory proof_, address[] memory tokensToClaim, uint256[] memory amountsToClaim) =
                    _generateMerkleTree(MerkleReader.MerkleArgs("1", 0, selectedUser, OP));

                vm.prank(selectedUser);
                rewards.claim(selectedUser, 0, tokensToClaim, amountsToClaim, proof_);
            }
            if (store.totalSelectedUsers() == totalTestUsers) {
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
        string[31] contractNames;
        address[][] coreContracts;
        uint256[] forksArray;
    }

    function _initHandler(InitHandlerSetupVars memory vars) internal {
        mapping(uint64 => uint256) storage forks = FORKS;

        for (uint256 i = 0; i < vars.chainIds.length; ++i) {
            forks[vars.chainIds[i]] = vars.forksArray[i];
        }
        _preDeploymentSetup();

        for (uint256 i = 0; i < vars.chainIds.length; ++i) {
            for (uint256 j = 0; j < vars.contractNames.length; ++j) {
                contracts[vars.chainIds[i]][bytes32(bytes(vars.contractNames[j]))] = vars.coreContracts[i][j];
            }
        }
    }

    /// @dev overrides basesetup _preDeploymentSetup so that forks are not created again
    function _preDeploymentSetup() internal override {
        mapping(uint64 => string) storage rpcURLs = RPC_URLS;

        rpcURLs[OP] = OPTIMISM_RPC_URL;
    }
}
