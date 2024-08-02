// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeploy5115To4626WrapperFactory } from "./Abstract.Deploy.5115To4626Factory.s.sol";

contract MainnetDeploy5115To4626Factory is AbstractDeploy5115To4626WrapperFactory {
    function deploy5115To4626Factory(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deploy5115To4626WrapperFactory(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
