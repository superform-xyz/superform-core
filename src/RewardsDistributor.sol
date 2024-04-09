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

    /// @dev maps the monthly rewards id to its corresponding merkle root
    mapping(uint256 monthId => bytes32 merkleRoot) public monthMerkleRoot;

    /// @dev mapping from monthId to claimer address to claimed status
    mapping(uint256 monthId => mapping(address claimerAddress => bool claimed)) public monthlyRewardsClaimed;

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
    function setMonthlyRewards(uint256 monthId_, bytes32 root_) external payable override onlyRewardsAdmin {
        if (root_ == ZERO_BYTES32) revert INVALID_MERKLE_ROOT();
        if (monthMerkleRoot[monthId_] != ZERO_BYTES32) revert MERKLE_ROOT_ALREADY_SET();
        if (monthId_ != 0 && monthMerkleRoot[monthId_ - 1] == ZERO_BYTES32) revert PREVIOUS_MONTHID_NOT_SET();

        monthMerkleRoot[monthId_] = root_;

        emit MonthSet(monthId_, root_);
    }

    /// @inheritdoc IRewardsDistributor
    function claim(
        address receiver_,
        uint256 monthId_,
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

        _claim(receiver_, monthId_, rewardTokens_, amountsClaimed_, tokensToClaim, proof_);

        emit RewardsClaimed(msg.sender, receiver_, monthId_, rewardTokens_, amountsClaimed_);
    }

    /// @inheritdoc IRewardsDistributor
    function batchClaim(
        address receiver_,
        uint256[] calldata monthIds_,
        address[][] calldata rewardTokens_,
        uint256[][] calldata amountsClaimed_,
        bytes32[][] calldata proofs_
    )
        external
        override
    {
        if (receiver_ == address(0)) revert INVALID_RECEIVER();

        uint256 len = monthIds_.length;

        if (len == 0) revert ZERO_ARR_LENGTH();
        if (len != proofs_.length) revert INVALID_BATCH_REQ();

        for (uint256 i; i < len; ++i) {
            uint256 tokensToClaim = rewardTokens_.length;

            if (tokensToClaim == 0) revert ZERO_ARR_LENGTH();
            if (tokensToClaim != amountsClaimed_[i].length) revert INVALID_BATCH_REQ();

            _claim(receiver_, monthIds_[i], rewardTokens_[i], amountsClaimed_[i], tokensToClaim, proofs_[i]);

            emit RewardsClaimed(msg.sender, receiver_, monthIds_[i], rewardTokens_[i], amountsClaimed_[i]);
        }
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IRewardsDistributor
    function verifyClaim(
        address claimer_,
        uint256 monthId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        bytes32[] calldata proof_
    )
        public
        view
        override
        returns (bool valid)
    {
        bytes32 root = monthMerkleRoot[monthId_];
        if (root == ZERO_BYTES32) revert MERKLE_ROOT_NOT_SET();

        /// @dev user cannot claim a monthly reward twice
        if (monthlyRewardsClaimed[monthId_][claimer_]) return false;

        bytes32 leaf =
            keccak256(bytes.concat(keccak256(abi.encode(claimer_, monthId_, rewardTokens_, amountsClaimed_))));
        return MerkleProof.verify(proof_, root, leaf);
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    /// @notice helper function for processing claim
    function _claim(
        address receiver_,
        uint256 monthId_,
        address[] calldata rewardTokens_,
        uint256[] calldata amountsClaimed_,
        uint256 tokensToClaim_,
        bytes32[] calldata proof_
    )
        internal
    {
        if (!verifyClaim(msg.sender, monthId_, rewardTokens_, amountsClaimed_, proof_)) revert INVALID_CLAIM();

        monthlyRewardsClaimed[monthId_][receiver_] = true;

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
        for (uint256 i = 0; i < tokensToClaim_; ++i) {
            IERC20(rewardTokens_[i]).safeTransfer(to_, amountsClaimed_[i]);
        }
    }
}
