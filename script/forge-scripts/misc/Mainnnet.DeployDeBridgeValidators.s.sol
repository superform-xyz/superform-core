// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeployDeBridgeValidators } from "./Abstract.Deploy.DeBridgeValidators.s.sol";

contract MainnetDeployDeBridgeValidatorsV2 is AbstractDeployDeBridgeValidators {
    function deployDeBridgeValidator(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployDebridge(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
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

        _addDeBridgeValidatorsToSuperRegistryStaging(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
