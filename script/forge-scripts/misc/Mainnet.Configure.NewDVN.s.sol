// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractConfigureNewDVN } from "./Abstract.Configure.NewDVN.s.sol";

contract MainnetConfigDVN is AbstractConfigureNewDVN {
    function configureDVN(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _configureNewDVN(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
