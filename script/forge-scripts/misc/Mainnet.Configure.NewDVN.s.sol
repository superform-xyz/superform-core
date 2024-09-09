// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractConfigureNewDVN } from "./Abstract.Configure.NewDVN.s.sol";
import "forge-std/console.sol";

contract MainnetConfigDVN is AbstractConfigureNewDVN {
    function configureReceiveDVN(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _configureReceiveDVN(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configureSendDVN(
        uint256 env,
        uint256 selectedSrcChainIndex,
        uint256 selectedDstChainIndex,
        uint256 useNewSalt
    )
        external
    {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 srcTrueIndex;
        uint256 dstTrueIndex;

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedSrcChainIndex] == chainIds[i]) {
                srcTrueIndex = i;
            }

            if (TARGET_CHAINS[selectedDstChainIndex] == chainIds[i]) {
                dstTrueIndex = i;
            }

            if (srcTrueIndex != 0 && dstTrueIndex != 0) break;
        }

        _configureSendDVN(env, selectedSrcChainIndex, srcTrueIndex, dstTrueIndex, Cycle.Prod, TARGET_CHAINS);
    }

    function configureReceiveDVN(
        uint256 env,
        uint256 selectedSrcChainIndex,
        uint256 selectedDstChainIndex,
        uint256 useNewSalt
    )
        external
    {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        uint256 srcTrueIndex;
        uint256 dstTrueIndex;

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedSrcChainIndex] == chainIds[i]) {
                srcTrueIndex = i;
            }

            if (TARGET_CHAINS[selectedDstChainIndex] == chainIds[i]) {
                dstTrueIndex = i;
            }

            if (srcTrueIndex != 0 && dstTrueIndex != 0) break;
        }

        _configureReceiveDVN(env, selectedSrcChainIndex, srcTrueIndex, dstTrueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
