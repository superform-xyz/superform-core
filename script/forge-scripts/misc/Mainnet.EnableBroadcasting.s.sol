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

        _enableBroadcasting(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
