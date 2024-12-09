// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractUpdatePriceFeeds } from "./Abstract.Update.PriceFeeds.s.sol";

contract MainnetUpdatePriceFeeds is AbstractUpdatePriceFeeds {
    function updatePriceFeeds(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env, false);
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _updatePriceFeeds(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
