// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "./Abstract.Deploy.Single.s.sol";

abstract contract EnvironmentUtils is AbstractDeploySingle {
    uint64[] TARGET_CHAINS;
    ///@dev ORIGINAL SALT
    bytes32 salt;

    /// new keeper addresses
    address BROADCAST_REGISTRY_PROCESSOR;
    address WORMHOLE_VAA_RELAYER;

    function _readContractsV1(
        uint256 env,
        string memory name,
        uint64 chainId,
        string memory contractName
    )
        internal
        view
        returns (address)
    {
        string memory json;
        string memory root = vm.projectRoot();
        json = string(
            abi.encodePacked(
                root,
                "/script/deployments/v1_",
                env == 0 ? "deployment/" : "staging_deployment/",
                vm.toString(uint256(chainId)),
                "/",
                name,
                "-latest.json"
            )
        );
        string memory file = vm.readFile(json);
        return vm.parseJsonAddress(file, string(abi.encodePacked(".", contractName)));
    }

    function _setEnvironment(uint256 env) internal {
        if (env == 0) {
            TARGET_CHAINS.push(ETH);
            TARGET_CHAINS.push(BSC);
            TARGET_CHAINS.push(AVAX);
            TARGET_CHAINS.push(POLY);
            TARGET_CHAINS.push(ARBI);
            TARGET_CHAINS.push(OP);
            TARGET_CHAINS.push(BASE);

            salt = "SunNeverSetsOnSuperformRealm";
        } else {
            TARGET_CHAINS.push(BSC);
            TARGET_CHAINS.push(ARBI);
            TARGET_CHAINS.push(OP);
            TARGET_CHAINS.push(BASE);

            salt = "StagingV1_0";
        }
        PAYMENT_ADMIN =
            env == 0 ? 0xD911673eAF0D3e15fe662D58De15511c5509bAbB : 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3;
        CSR_PROCESSOR =
            env == 0 ? 0x23c658FE050B4eAeB9401768bF5911D11621629c : 0x2759142A9e3cBbcCc1E3d5F76490eEE4007B8943;
        CSR_UPDATER = env == 0 ? 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f : 0xF1c73958118F22Fc3A3947f405DcEBF08a1E68f7;
        DST_SWAPPER = env == 0 ? 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C : 0x3ea519270248BdEE4a939df20049E02290bf9CaF;
        CSR_RESCUER = env == 0 ? 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5 : 0xe1A61d90554131314cB30dB55B8AD4F4b6e21C3a;
        CSR_DISPUTER =
            env == 0 ? 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a : 0xe9F074d003b377A197D336B8a1c86EdaA6cC4dEF;
        SUPERFORM_RECEIVER =
            env == 0 ? 0x1a6805487322565202848f239C1B5bC32303C2FE : 0x46F15EDC21f7eed6D1eb01e5Abe993Dc6c6A78BB;
        EMERGENCY_ADMIN =
            env == 0 ? 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490 : 0x6A5DD913fE3CB5193E09D1810a3b9ff1C0f9c0D6;
        SUPER_POSITIONS_NAME = env == 0 ? "SuperPositions" : "StagingSuperPositions";

        // BROADCASTING
        BROADCAST_REGISTRY_PROCESSOR =
            env == 0 ? 0x98616F52063d2A301be71386D381F43176A04F0f : 0x65c2d7e8d31C845894491ABe5789Ba1e5d4382fC;

        WORMHOLE_VAA_RELAYER =
            env == 0 ? 0x1A86b5c1467331A3A52572663FDBf037A9e29719 : 0xaD1bF3301971Ecd9E6219423129e360774ABEA68;
    }
}
