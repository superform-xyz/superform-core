// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {AbstractDeploySingle} from "./Abstract.Deploy.Single.s.sol";
import {MockERC20} from "test/mocks/MockERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {VaultMock} from "test/mocks/VaultMock.sol";
import {ERC4626TimelockMock} from "test/mocks/ERC4626TimelockMock.sol";
import {kycDAO4626} from "super-vaults/kycdao-4626/kycdao4626.sol";
import {AggregatorV3Interface} from "test/utils/AggregatorV3Interface.sol";

contract TestMainnetDeploySingle is AbstractDeploySingle {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/

    uint64[] SELECTED_CHAIN_IDS = [56, 137, 43114]; /// @dev BSC, POLY & AVAX

    /// @notice The main script entrypoint
    function deploy(uint256 selectedChainIndex) external {
        _preDeploymentSetup();
        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (SELECTED_CHAIN_IDS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _deploy(selectedChainIndex, trueIndex, Cycle.Prod, SELECTED_CHAIN_IDS);
    }
}
