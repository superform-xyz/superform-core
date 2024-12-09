// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeployRouterPlus } from "./Abstract.Deploy.RouterPlus.s.sol";

contract MainnetDeployRouterPlus is AbstractDeployRouterPlus {
    function deployRouterPlusStaging(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }
        if (env == 1) {
            _deployRouterPlusStaging(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        }
    }

    function deployRouterPlusProd(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }
        if (env == 0) {
            _deployRouterPlus(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        }
    }

    function configureRouterPlusProd(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }
        if (env == 0) {
            _configureRouterPlusProd(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        }
    }
}
