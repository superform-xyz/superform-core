// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeployLiFiValidatorV2 } from "./Abstract.Deploy.LiFiValidatorV2.s.sol";

contract MainnetDeployLiFiValidatorV2 is AbstractDeployLiFiValidatorV2 {
    function deployLiFiValidatorV2(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployLiFiValidatorV2(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configureSuperRegistry(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        assert(env == 1);

        _addLiFiValidatorV2ToSuperRegistryStaging(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
