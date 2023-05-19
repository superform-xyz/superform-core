// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {IQuorumManager} from "../../interfaces/IQuorumManager.sol";
import {Error} from "../../utils/Error.sol";

abstract contract QuorumManager is IQuorumManager {
    /*///////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(uint16 srcChainId => uint256 quorum) internal requiredQuorum;

    /*///////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @dev NOTE: ability to batch set quorum

    /// @inheritdoc IQuorumManager
    function setRequiredMessagingQuorum(
        uint16 srcChainId_,
        uint256 quorum_
    ) external virtual {}

    /*///////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IQuorumManager
    function getRequiredMessagingQuorum(
        uint16 srcChainId_
    ) public view returns (uint256 quorum_) {
        /// @dev no chain can have chain id zero. (validates that here)
        if (srcChainId_ == 0) {
            revert Error.INVALID_INPUT_CHAIN_ID();
        }
        return requiredQuorum[srcChainId_];
    }
}
