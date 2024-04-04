// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractUpdatePaymentHelper } from "./Abstract.Update.PaymentHelper.s.sol";

contract MainnetUpdatePaymentHelper is AbstractUpdatePaymentHelper {
    function updatePaymentHelper(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _updatePaymentHelper(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
