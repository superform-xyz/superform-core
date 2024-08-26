// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "./Abstract.Deploy.Single.s.sol";

abstract contract EnvironmentUtils is AbstractDeploySingle {
    uint64[] TARGET_CHAINS;
    ///@dev ORIGINAL SALT
    bytes32 salt;

    /*
    !WARNING if adding new chains later, deploy them ONE BY ONE in the begining of the below array
    !WARNING example below:
    uint64[] TARGET_DEPLOYMENT_CHAINS = [BASE];
    uint64[] FINAL_DEPLOYED_CHAINS = [BASE, ETH, AVAX, GNOSIS];
    uint64[] TARGET_CHAINS = [ETH, AVAX, GNOSIS]; -> this is in Environment Utils

    original was:
    uint64[] TARGET_DEPLOYMENT_CHAINS = [ETH, AVAX, GNOSIS];
    uint64[] FINAL_DEPLOYED_CHAINS = [ETH, AVAX, GNOSIS];
    */
    //!WARNING ENUSRE output folder has correct addresses of the deployment!
    //!WARNING CHECK LATEST PAYMENT HELPER CONFIGURATION TO ENSURE IT'S UP TO DATE

    uint64[] TARGET_DEPLOYMENT_CHAINS = [LINEA];
    uint64[] FINAL_DEPLOYED_CHAINS;

    function _setEnvironment(uint256 env, bool useNewSalt) internal {
        /// Production
        if (env == 0) {
            TARGET_CHAINS.push(ETH);
            TARGET_CHAINS.push(BSC);
            TARGET_CHAINS.push(AVAX);
            TARGET_CHAINS.push(POLY);
            TARGET_CHAINS.push(ARBI);
            TARGET_CHAINS.push(OP);
            TARGET_CHAINS.push(BASE);
            TARGET_CHAINS.push(FANTOM);

            if (useNewSalt) {
                salt = "SunNeverSetsOnSuperformRealmV2";
            } else {
                salt = "SunNeverSetsOnSuperformRealm";
            }

            PAYMENT_ADMIN = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
            CSR_PROCESSOR = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
            CSR_UPDATER = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
            DST_SWAPPER = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
            CSR_RESCUER = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
            CSR_DISPUTER = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
            SUPERFORM_RECEIVER = 0x1a6805487322565202848f239C1B5bC32303C2FE;
            EMERGENCY_ADMIN = 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490;
            REWARDS_ADMIN = 0xf82F3D7Df94FC2994315c32322DA6238cA2A2f7f;
            SUPER_POSITIONS_NAME = "SuperPositions";

            // BROADCASTING
            BROADCAST_REGISTRY_PROCESSOR = 0x98616F52063d2A301be71386D381F43176A04F0f;
            WORMHOLE_VAA_RELAYER = 0x1A86b5c1467331A3A52572663FDBf037A9e29719;
            // Staging
        } else if (env == 1) {
            TARGET_CHAINS.push(BSC);
            TARGET_CHAINS.push(ARBI);
            TARGET_CHAINS.push(OP);
            TARGET_CHAINS.push(BASE);
            TARGET_CHAINS.push(FANTOM);

            salt = "StagingV1_0";

            PAYMENT_ADMIN = 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3;
            CSR_PROCESSOR = 0x2759142A9e3cBbcCc1E3d5F76490eEE4007B8943;
            CSR_UPDATER = 0xF1c73958118F22Fc3A3947f405DcEBF08a1E68f7;
            DST_SWAPPER = 0x3ea519270248BdEE4a939df20049E02290bf9CaF;
            CSR_RESCUER = 0xe1A61d90554131314cB30dB55B8AD4F4b6e21C3a;
            CSR_DISPUTER = 0xe9F074d003b377A197D336B8a1c86EdaA6cC4dEF;
            SUPERFORM_RECEIVER = 0x46F15EDC21f7eed6D1eb01e5Abe993Dc6c6A78BB;
            EMERGENCY_ADMIN = 0x6A5DD913fE3CB5193E09D1810a3b9ff1C0f9c0D6;
            REWARDS_ADMIN = 0x1F05a8Ff6d895Ba04C84c5031c5d63FA1afCDA6F;
            SUPER_POSITIONS_NAME = "StagingSuperPositions";

            // BROADCASTING
            BROADCAST_REGISTRY_PROCESSOR = 0x65c2d7e8d31C845894491ABe5789Ba1e5d4382fC;
            WORMHOLE_VAA_RELAYER = 0xaD1bF3301971Ecd9E6219423129e360774ABEA68;

            // Tenderly
        } else if (env == 2) {
            TARGET_CHAINS.push(ETH);
            TARGET_CHAINS.push(OP);
            TARGET_CHAINS.push(ARBI);

            PAYMENT_ADMIN = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
            CSR_PROCESSOR = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
            CSR_UPDATER = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
            DST_SWAPPER = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
            CSR_RESCUER = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
            CSR_DISPUTER = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
            SUPERFORM_RECEIVER = 0x1a6805487322565202848f239C1B5bC32303C2FE;
            EMERGENCY_ADMIN = 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490;
            REWARDS_ADMIN = 0xf82F3D7Df94FC2994315c32322DA6238cA2A2f7f;
            SUPER_POSITIONS_NAME = "SuperPositions";

            // BROADCASTING
            BROADCAST_REGISTRY_PROCESSOR = 0x98616F52063d2A301be71386D381F43176A04F0f;
            WORMHOLE_VAA_RELAYER = 0x1A86b5c1467331A3A52572663FDBf037A9e29719;

            salt = "Tenderly";
        } else {
            revert("Invalid environment");
        }

        FINAL_DEPLOYED_CHAINS = TARGET_DEPLOYMENT_CHAINS;

        for (uint256 i = 0; i < TARGET_CHAINS.length; ++i) {
            FINAL_DEPLOYED_CHAINS.push(TARGET_CHAINS[i]);
        }
    }
}
