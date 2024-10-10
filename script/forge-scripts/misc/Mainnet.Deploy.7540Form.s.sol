// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeploy7540Form } from "./Abstract.Deploy.7540Form.s.sol";

contract MainnetDeploy7540Form is AbstractDeploy7540Form {
    function deploy5115Form(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deploy7540Form(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configure7540Form(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        if (env == 1) {
            _configureSettingsStaging(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        } else {
            _configureSettingsProd(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
        }
    }
}
