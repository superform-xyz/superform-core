// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import { AbstractDeploySingle } from "./Abstract.Deploy.Single.s.sol";

contract TestMainnetDeploySingle is AbstractDeploySingle {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    uint64[] SELECTED_CHAIN_IDS = [56, 137, 43_114];
    /// @dev BSC, POLY & AVAX

    /// @notice The main stage 1 script entrypoint
    function deployStage1(uint256 selectedChainIndex) external {
        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (SELECTED_CHAIN_IDS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }

        _deployStage1(selectedChainIndex, trueIndex, Cycle.Prod, SELECTED_CHAIN_IDS);
    }

    /// @dev stage 2 must be called only after stage 1 is complete for all chains!
    function deployStage2(uint256 selectedChainIndex) external {
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (SELECTED_CHAIN_IDS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployStage2(selectedChainIndex, trueIndex, Cycle.Prod, SELECTED_CHAIN_IDS);
    }
}
