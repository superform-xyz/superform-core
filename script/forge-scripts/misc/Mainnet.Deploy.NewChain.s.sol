// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { EnvironmentUtils } from "../EnvironmentUtils.s.sol";

contract MainnetDeployNewChain is EnvironmentUtils {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    /// @notice The main stage 1 script entrypoint
    function deployStage1(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;

                break;
            }
        }

        _deployStage1(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, salt);
    }

    /// @dev stage 2 must be called only after stage 1 is complete for all chains!
    function deployStage2(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }
        _deployStage2(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, FINAL_DEPLOYED_CHAINS);
    }

    /// @dev stage 3 must be called only after stage 1 is complete for all chains!
    function deployStage3(uint256 env, uint256 selectedChainIndex, uint256 useNewSalt) external {
        _setEnvironment(env, useNewSalt == 1 ? true : false);

        _preDeploymentSetup();

        uint256 trueIndex;

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deployStage3(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, true);
    }

    /// @dev configures stage 2 for previous chains for the newly added chain with emergency admin
    function configurePreviousChainsWithEmergencyAdmin(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env, false);

        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        /// @dev set execute to false to simulate the transactions
        _configurePreviouslyDeployedChainsWithVaultLimit(
            env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS, TARGET_DEPLOYMENT_CHAINS[0]
        );
    }

    /// @dev configures stage 2 for previous chains for the newly added chain with protocol admin
    function configurePreviousChainsWithProtocolAdmin(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env, false);

        _preDeploymentSetup();

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        /// @dev set execute to false to simulate the transactions
        _configurePreviouslyDeployedChainsWithNewChain(
            env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS, TARGET_DEPLOYMENT_CHAINS[0], true
        );
    }

    /// @dev only revoke burner addresses after smoke tests are complete
    function revokeBurnerAddress(uint256 env, uint256 selectedChainIndex) external {
        _setEnvironment(env, false);

        _preDeploymentSetup();

        uint256 trueIndex;

        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_DEPLOYMENT_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _revokeFromBurnerWallets(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS);
    }
}
