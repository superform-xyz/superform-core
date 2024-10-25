// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractPreBeraLaunch } from "./Abstract.Configure.PreBeraLaunch.s.sol";
import "forge-std/console.sol";

contract MainnetConfigPreBeraDVN is AbstractPreBeraLaunch {
    function setBlastDelegate(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _setBlastDelegate(env, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configure(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _configure(env, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
