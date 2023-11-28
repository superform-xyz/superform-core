// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeploySingle } from "./Abstract.Deploy.Single.s.sol";

contract MainnetDeploy is AbstractDeploySingle {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    uint64[] TARGET_DEPLOYMENT_CHAINS = [BSC, POLY, AVAX];
    ///@dev ORIGINAL SALT bytes32 constant salt = "CANTINA_DEPLOYMENT_4";

    /// @notice The main stage 1 script entrypoint
    function deployStage1(uint256 selectedChainIndex, uint256 salt) external {
        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }

        _deployStage1(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, keccak256(abi.encode(salt)));
    }

    /// @dev stage 2 must be called only after stage 1 is complete for all chains!
    function deployStage2(uint256 selectedChainIndex) external {
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployStage2(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, TARGET_DEPLOYMENT_CHAINS);
    }

    /// @dev stage 3 must be called only after stage 1 is complete for all chains!
    function deployStage3(uint256 selectedChainIndex) external {
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployStage3(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS);
    }
}
