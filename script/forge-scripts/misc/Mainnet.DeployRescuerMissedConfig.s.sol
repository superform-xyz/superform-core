// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractRescuerMissedConfig } from "./Abstract.Deploy.RescuerMissedConfig.s.sol";

contract MainnetDeployRescuerMissedConfig is AbstractRescuerMissedConfig {
    function configureRescuer(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        if (TARGET_CHAINS[selectedChainIndex] == LINEA) {
            _configureRescuerLinea(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        } else if (TARGET_CHAINS[selectedChainIndex] == BLAST) {
            _configureRescuerBlast(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        }
    }
}
