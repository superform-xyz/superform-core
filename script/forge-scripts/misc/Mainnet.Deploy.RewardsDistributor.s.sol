// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeployRewardsDistributor } from "./Abstract.Deploy.RewardsDistributor.s.sol";

contract MainnetDeployRewardsDistributor is AbstractDeployRewardsDistributor {
    function deployRewardsDistributor(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env, false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployRewardsDistributor(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configureSettings(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env, false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        if (env == 0) {
            _configureSettingsProd(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        } else if (env == 1) {
            _configureSettingsStaging(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        }
    }
}
