// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeploySingle } from "./Abstract.Deploy.Single.s.sol";

contract MainnetDeployNewChain is AbstractDeploySingle {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    /*
    !WARNING if adding new chains later, deploy them ONE BY ONE in the begining of the below array
    !WARNING example below:
    uint64[] TARGET_DEPLOYMENT_CHAINS = [BASE];
    uint64[] FINAL_DEPLOYED_CHAINS = [BASE, ETH, AVAX, GNOSIS];
    uint64[] PREVIOUS_DEPLOYMENT = [ETH, AVAX, GNOSIS];

    original was:
    uint64[] TARGET_DEPLOYMENT_CHAINS = [ETH, AVAX, GNOSIS];
    uint64[] FINAL_DEPLOYED_CHAINS = [ETH, AVAX, GNOSIS];
    */
    //!WARNING ENUSRE output folder has correct addresses of the deployment!

    uint64[] TARGET_DEPLOYMENT_CHAINS = [ETH];
    uint64[] FINAL_DEPLOYED_CHAINS = [ETH, BSC, AVAX, POLY, ARBI, OP, BASE];
    uint64[] PREVIOUS_DEPLOYMENT = [BSC, AVAX, POLY, ARBI, OP, BASE];

    ///@dev ORIGINAL SALT
    bytes32 constant salt = "SunNeverSetsOnSuperformRealm";

    /// @notice The main stage 1 script entrypoint
    function deployStage1(uint256 selectedChainIndex) external {
        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }

        _deployStage1(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, salt);
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

        _deployStage2(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, FINAL_DEPLOYED_CHAINS);
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

        _deployStage3(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, true);
    }

    /// @dev configures stage 2 for previous chains for the newly added chain
    function configurePreviousChains(uint256 selectedChainIndex) external {
        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (PREVIOUS_DEPLOYMENT[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _configurePreviouslyDeployedChainsWithNewChain(
            selectedChainIndex, trueIndex, Cycle.Prod, PREVIOUS_DEPLOYMENT, TARGET_DEPLOYMENT_CHAINS[0]
        );
    }
}
