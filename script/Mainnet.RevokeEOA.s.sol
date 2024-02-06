// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractRevokeEOA } from "./Abstract.RevokeEOA.s.sol";

contract RevokeEOAs is AbstractRevokeEOA {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/
    uint64[] TARGET_DEPLOYMENT_CHAINS = [ETH, BSC, AVAX, POLY, ARBI, OP, BASE];

    ///@dev ORIGINAL SALT
    bytes32 constant salt = "SunNeverSetsOnSuperformRealm";

    /// @dev stage 3 must be called only after stage 1 is complete for all chains!
    function revokeEOA(uint256 selectedChainIndex) external {
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _revokeEOAs(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS);
    }
}
