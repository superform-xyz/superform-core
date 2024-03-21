// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractEnableBroadcasting } from "./Abstract.EnableBroadcasting.s.sol";

contract MainnetEnableBroadcasting is AbstractEnableBroadcasting {
    function enableBroadcasting(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        env == 1
            ? _enableBroadcasting(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS)
            : _enableBroadcastingProd(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function fixRevokeRole(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        env == 1
            ? _revokeRole(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS)
            : _revokeRoleProd(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
