// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractSuperRegistryLiFiValidatorV2 } from "./Abstract.SuperRegistry.LiFiValidatorV2Paymaster.s.sol";

contract MainnetSuperRegistryLiFiValidatorV2Paymaster is AbstractSuperRegistryLiFiValidatorV2 {
    function configureSuperRegistry(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }
        assert(env == 0);

        _addPaymasterLiFiValidatorV2ToSuperRegistryProd(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
