// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { AbstractDeploySingle } from "./Abstract.Deploy.Single.s.sol";

contract MainnetStagingDeploy is AbstractDeploySingle {
    /*//////////////////////////////////////////////////////////////
                        SELECT CHAIN IDS TO DEPLOY HERE
    //////////////////////////////////////////////////////////////*/
    uint64[] TARGET_DEPLOYMENT_CHAINS = [BSC, ARBI, OP, BASE];

    ///@dev ORIGINAL SALT
    bytes32 constant salt = "StagingV1_0";

    /// @notice The main stage 1 script entrypoint
    function deployStage1(uint256 selectedChainIndex) external {
        PAYMENT_ADMIN = 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3;
        CSR_PROCESSOR = 0x2759142A9e3cBbcCc1E3d5F76490eEE4007B8943;
        CSR_UPDATER = 0xF1c73958118F22Fc3A3947f405DcEBF08a1E68f7;
        DST_SWAPPER = 0x3ea519270248BdEE4a939df20049E02290bf9CaF;
        CSR_RESCUER = 0xe1A61d90554131314cB30dB55B8AD4F4b6e21C3a;
        CSR_DISPUTER = 0xe9F074d003b377A197D336B8a1c86EdaA6cC4dEF;
        SUPERFORM_RECEIVER = 0x46F15EDC21f7eed6D1eb01e5Abe993Dc6c6A78BB;
        EMERGENCY_ADMIN = 0x6A5DD913fE3CB5193E09D1810a3b9ff1C0f9c0D6;
        SUPER_POSITIONS_NAME = "StagingSuperPositions";
    
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

        _deployStage3(selectedChainIndex, trueIndex, Cycle.Prod, TARGET_DEPLOYMENT_CHAINS, false);
    }
}
