// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.21;

import { IQuorumManager } from "../../interfaces/IQuorumManager.sol";
import { Error } from "../../utils/Error.sol";

/// @title QuorumManager
/// @author ZeroPoint Labs
/// @dev separates quorum management concerns into an abstract contract. Can be re-used (currently used by
/// superRegistry) to set different quorums per amb in different areas of the protocol
abstract contract QuorumManager is IQuorumManager {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(uint64 srcChainId => uint256 quorum) internal requiredQuorum;

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IQuorumManager
    function setRequiredMessagingQuorum(uint64 srcChainId_, uint256 quorum_) external virtual;

    /*///////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IQuorumManager
    function getRequiredMessagingQuorum(uint64 srcChainId_) public view returns (uint256 quorum_) {
        /// @dev no chain can have chain id zero. (validates that here)
        if (srcChainId_ == 0) {
            revert Error.INVALID_INPUT_CHAIN_ID();
        }
        return requiredQuorum[srcChainId_];
    }
}
