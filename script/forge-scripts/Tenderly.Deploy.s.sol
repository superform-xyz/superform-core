// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { EnvironmentUtils } from "./EnvironmentUtils.s.sol";

contract TenderlyDeploy is EnvironmentUtils {
    /// @notice The main stage 1 script entrypoint
    function deployStage1(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }

        _deployStage1(env, selectedChainIndex, trueIndex, Cycle.Dev, TARGET_CHAINS, keccak256(abi.encode(salt)));
    }
}
