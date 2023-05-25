// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {AbstractDeploy} from "./Abstract.Deploy.s.sol";
import {MockERC20} from "../src/test/mocks/MockERC20.sol";
import {IERC4626} from "../src/vendor/IERC4626.sol";
import {VaultMock} from "../src/test/mocks/VaultMock.sol";
import {ERC4626TimelockMock} from "../src/test/mocks/ERC4626TimelockMock.sol";
import {kycDAO4626} from "super-vaults/kycdao-4626/kycdao4626.sol";
import {AggregatorV3Interface} from "../src/test/utils/AggregatorV3Interface.sol";

contract TestMainnetDeploy is AbstractDeploy {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    uint64[] SELECTED_CHAIN_IDS = [56, 137, 43114]; /// @dev BSC, POLY & AVAX
    uint256[] EVM_CHAIN_IDS = [56, 137, 43114]; /// @dev BSC, POLY & AVAX
    Chains[] SELECTED_CHAIN_NAMES = [Chains.Bsc, Chains.Polygon, Chains.Avalanche];

    /// @notice The main script entrypoint
    function run() external {
        uint256[] memory forkIds = _preDeploymentSetup(SELECTED_CHAIN_NAMES, Cycle.Prod);
        uint256 chainIdIndex;

        /// @dev Deployment stage 1
        for (uint256 i = 0; i < SELECTED_CHAIN_IDS.length; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (chainIds[j] == SELECTED_CHAIN_IDS[i]) {
                    chainIdIndex = j;
                    break;
                }
            }
            _setupStage1(chainIdIndex, Cycle.Prod, SELECTED_CHAIN_IDS, EVM_CHAIN_IDS, forkIds[i]);
        }

        /// @dev Deployment Stage 2 - Setup trusted remotes and deploy superforms. This must be done after the rest of the protocol has been deployed on all chains
        for (uint256 i = 0; i < SELECTED_CHAIN_IDS.length; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (chainIds[j] == SELECTED_CHAIN_IDS[i]) {
                    chainIdIndex = j;
                    break;
                }
            }
            _setupStage2(chainIdIndex, Cycle.Prod, SELECTED_CHAIN_IDS, forkIds[i]);
        }
    }
}
