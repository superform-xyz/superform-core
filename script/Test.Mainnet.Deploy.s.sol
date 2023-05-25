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

    uint64[] SELECTED_CHAIN_IDS = [56, 137, 250]; /// @dev BSC, POLY & FTM
    uint256[] EVM_CHAIN_IDS = [56, 137, 250]; /// @dev BSC, POLY & FTM
    Chains[] SELECTED_CHAIN_NAMES = [Chains.Bsc_Fork, Chains.Polygon_Fork, Chains.Fantom_Fork];

    /*

Chain 56

Estimated gas price: 2 gwei

Estimated total gas used for script: 66299224

Estimated amount required: 0.132598448 BNB * 5

==========================

==========================

Chain 137

Estimated gas price: 219.102025898 gwei

Estimated total gas used for script: 66970773

Estimated amount required: 14.673432040255079154 MATIC * 5

==========================

==========================

Chain 250

Estimated gas price: 69.389531536 gwei

Estimated total gas used for script: 66959399

Estimated amount required: 4.646281328542106864 FTM * 5
*/
    /// @notice The main script entrypoint
    function run() external {
        uint256[] memory forkIds = _preDeploymentSetup(SELECTED_CHAIN_NAMES, Cycle.Dev);
        uint256 chainIdIndex;

        /// @dev Deployment stage 1
        for (uint256 i = 0; i < SELECTED_CHAIN_IDS.length; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (chainIds[j] == SELECTED_CHAIN_IDS[i]) {
                    chainIdIndex = j;
                    break;
                }
            }
            _setupStage1(chainIdIndex, Cycle.Dev, SELECTED_CHAIN_IDS, EVM_CHAIN_IDS, forkIds[i]);
        }

        /// @dev Deployment Stage 2 - Setup trusted remotes and deploy superforms. This must be done after the rest of the protocol has been deployed on all chains
        for (uint256 i = 0; i < SELECTED_CHAIN_IDS.length; i++) {
            for (uint256 j = 0; j < chainIds.length; j++) {
                if (chainIds[j] == SELECTED_CHAIN_IDS[i]) {
                    chainIdIndex = j;
                    break;
                }
            }
            _setupStage2(chainIdIndex, Cycle.Dev, SELECTED_CHAIN_IDS, forkIds[i]);
        }
    }
}
