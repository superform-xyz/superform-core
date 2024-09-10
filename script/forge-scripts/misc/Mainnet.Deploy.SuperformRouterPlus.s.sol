// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeployRouterPlus } from "./Abstract.Deploy.RouterPlus.s.sol";

contract MainnetDeployRouterPlus is AbstractDeployRouterPlus {
    function deployRouterPlus(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployRouterPlus(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
