// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeployBridgeAdaptersV2 } from "./Abstract.Deploy.BridgeAdaptersV2.s.sol";

contract MainnetDeployBridgeAdaptersV2 is AbstractDeployBridgeAdaptersV2 {
    function deployBridgeAdaptersV2(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployBridgeAdaptersV2(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configureSuperRegistry(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        assert(env == 1);

        _addNewBridgeAdaptersSuperRegistryStaging(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configureDeploymentAdapters(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _configureDeployedAdapters(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
