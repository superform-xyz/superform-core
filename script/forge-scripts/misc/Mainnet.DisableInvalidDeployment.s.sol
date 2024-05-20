// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { EnvironmentUtils } from "../EnvironmentUtils.s.sol";

contract DisableInvalidDeployment is EnvironmentUtils {
    /// @notice Disable invalid deployment
    function disableInvalidDeployment(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }

        _disableInvalidDeployment(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS);
    }
}
