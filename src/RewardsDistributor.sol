// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// library imports
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

/// local imports
import { Error } from "src/libraries/Error.sol";
import { ISuperRBAC } from "src/interfaces/ISuperRBAC.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IRewardsDistributor } from "src/interfaces/IRewardsDistributor.sol";

/// @title SuperFrens
/// @author Zeropoint Labs
/// @notice This will be SUPERFORM_RECEIVER in SuperRegistry. Also, requires a new REWARDS_ADMIN_ROLE (a fireblocks
/// address)
contract RewardsDistributor is IRewardsDistributor {
    using SafeERC20 for IERC20;

    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                         //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    uint64 public immutable CHAIN_ID;
    bytes32 internal constant ZERO_BYTES32 = bytes32(0);

    //////////////////////////////////////////////////////////////
    //                      STATE VARIABLES                     //
    //////////////////////////////////////////////////////////////

    uint256 public currentPeriodId;

    /// @dev maps the periodic rewards id to its corresponding merkle root
    mapping(uint256 periodId => bytes32 merkleRoot) public periodicRewardsMerkleRoot;

    /// @dev mapping from periodId to claimer address to claimed status
    mapping(uint256 periodId => mapping(address claimerAddress => bool claimed)) public periodicRewardsClaimed;

    //////////////////////////////////////////////////////////////
    //                       MODIFIERS                          //
    //////////////////////////////////////////////////////////////

    modifier onlyRewardsAdmin() {
        if (
            !ISuperRBAC(superRegistry.getAddress(keccak256("SUPER_RBAC"))).hasRole(
                keccak256("REWARDS_ADMIN_ROLE"), msg.sender
            )
        ) {
            revert NOT_REWARDS_ADMIN();
        }
        _;
    }

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    /// @param superRegistry_ the superform registry contract
    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }

        if (block.chainid > type(uint64).max) {
            revert Error.BLOCK_CHAIN_ID_OUT_OF_BOUNDS();
        }

        superRegistry = ISuperRegistry(superRegistry_);
        CHAIN_ID = uint64(block.chainid);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IRewardsDistributor
    function setPeriodicRewards(bytes32 root_) external payable override onlyRewardsAdmin {
        if (root_ == ZERO_BYTES32) revert INVALID_MERKLE_ROOT();

        uint256 periodId = currentPeriodId;

        periodicRewardsMerkleRoot[periodId] = root_;

        ++currentPeriodId;
        emit PeriodicRewardsSet(periodId, root_);
    }

    /// @inheritdoc IRewardsDistributor
    function claim(
        address receiver_,
        uint256 periodId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        bytes32[] calldata proof_
    )
        external
        override
    {
        if (receiver_ == address(0)) revert INVALID_RECEIVER();

        uint256 tokensToClaim = rewardTokens_.length;

        if (tokensToClaim == 0) revert ZERO_ARR_LENGTH();
        if (tokensToClaim != amountsClaimed_.length) revert INVALID_BATCH_REQ();

        _claim(receiver_, periodId_, rewardTokens_, amountsClaimed_, tokensToClaim, proof_);

        emit RewardsClaimed(msg.sender, receiver_, periodId_, rewardTokens_, amountsClaimed_);
    }

    /// @inheritdoc IRewardsDistributor
    function batchClaim(
        address receiver_,
        uint256[] calldata periodIds_,
        address[][] calldata rewardTokens_,
        uint256[][] calldata amountsClaimed_,
        bytes32[][] calldata proofs_
    )
        external
        override
    {
        if (receiver_ == address(0)) revert INVALID_RECEIVER();

        uint256 len = periodIds_.length;

        if (len == 0) revert ZERO_ARR_LENGTH();
        if (len != proofs_.length) revert INVALID_BATCH_REQ();

        for (uint256 i; i < len; ++i) {
            uint256 tokensToClaim = rewardTokens_.length;

            if (tokensToClaim == 0) revert ZERO_ARR_LENGTH();
            if (tokensToClaim != amountsClaimed_[i].length) revert INVALID_BATCH_REQ();

            _claim(receiver_, periodIds_[i], rewardTokens_[i], amountsClaimed_[i], tokensToClaim, proofs_[i]);

            emit RewardsClaimed(msg.sender, receiver_, periodIds_[i], rewardTokens_[i], amountsClaimed_[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IRewardsDistributor
    function verifyClaim(
        address claimer_,
        uint256 periodId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        bytes32[] calldata proof_
    )
        public
        view
        override
        returns (bool valid)
    {
        bytes32 root = periodicRewardsMerkleRoot[periodId_];
        if (root == ZERO_BYTES32) revert MERKLE_ROOT_NOT_SET();

        /// @dev user cannot claim a periodic reward twice
        if (periodicRewardsClaimed[periodId_][claimer_]) return false;

        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(claimer_, periodId_, rewardTokens_, amountsClaimed_, CHAIN_ID)))
        );
        return MerkleProof.verify(proof_, root, leaf);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @notice helper function for processing claim
    function _claim(
        address receiver_,
        uint256 periodId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        uint256 tokensToClaim_,
        bytes32[] calldata proof_
    )
        internal
    {
        if (!verifyClaim(msg.sender, periodId_, rewardTokens_, amountsClaimed_, proof_)) revert INVALID_CLAIM();

        periodicRewardsClaimed[periodId_][receiver_] = true;

        _transferRewards(receiver_, rewardTokens_, amountsClaimed_, tokensToClaim_);
    }

    /// @notice transfer token rewards to the receiver
    function _transferRewards(
        address to_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        uint256 tokensToClaim_
    )
        internal
    {
        for (uint256 i; i < tokensToClaim_; ++i) {
            IERC20(rewardTokens_[i]).safeTransfer(to_, amountsClaimed_[i]);
        }
    }
}
