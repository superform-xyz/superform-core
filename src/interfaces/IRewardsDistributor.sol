// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title IRewardsDistributor
/// @notice interface for the RewardsDistributor contract
/// @author Zeropoint Labs
interface IRewardsDistributor {
    //////////////////////////////////////////////////////////////
    //                     ERRORS                               //
    //////////////////////////////////////////////////////////////
    error NOT_REWARDS_ADMIN();

    error INVALID_CLAIM();

    error INVALID_BATCH_REQ();

    error INVALID_MERKLE_ROOT();

    error INVALID_RECEIVER();

    error MERKLE_ROOT_NOT_SET();

    error ZERO_ARR_LENGTH();

    //////////////////////////////////////////////////////////////
    //                      EVENTS                              //
    //////////////////////////////////////////////////////////////

    /// @dev Emitted when tokens are claimed.
    event RewardsClaimed(
        address indexed claimer,
        address indexed receiver,
        uint256 periodId,
        address[] rewardTokens_,
        uint256[] amountsClaimed_
    );

    /// @dev Emitted when new periodic rewards are set.
    event PeriodicRewardsSet(uint256 indexed periodId, bytes32 merkleRoot);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @notice allows owner to set the merkle root for the current period rewards
    /// @param root_ is the merkle root for that period generated offchain
    /// @dev [gas-opt]: function is payable to avoid msg.value checks
    function setPeriodicRewards(bytes32 root_) external payable;

    /// @notice lets an account claim a given quantity of reward tokens.
    /// @param receiver_ is the receiver of the tokens to claim.
    /// @param periodId_ is the specific period to claim
    /// @param rewardTokens_ are the address of the rewards token to claim on the specific period
    /// @param amountsClaimed_ adre the amount of tokens to claim for each reward token
    /// @param proof_ the merkle proof
    function claim(
        address receiver_,
        uint256 periodId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        bytes32[] calldata proof_
    )
        external;

    /// @notice is a batching version of claim()
    function batchClaim(
        address receiver_,
        uint256[] calldata periodIds_,
        address[][] calldata rewardTokens_,
        uint256[][] calldata amountsClaimed_,
        bytes32[][] calldata proofs_
    )
        external;

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @notice helps validate if the claim is valid
    /// @param claimer_ is the address of the claiming wallet
    /// @param periodId_ is the period identifier
    /// @param rewardTokens_ are the address of the rewards token to claim on the specific period
    /// @param amountsClaimed_ adre the amount of tokens to claim for each reward token
    /// @param proof_ is the merkle proof
    /// @dev returns false even if proof is valid and user already claimed their periodic rewards
    function verifyClaim(
        address claimer_,
        uint256 periodId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        bytes32[] calldata proof_
    )
        external
        view
        returns (bool valid);
}
