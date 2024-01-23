// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/MainnetBaseSetup.sol";

contract SmokeTest is MainnetBaseSetup {
    function setUp() public override {
        /// @dev FIXME change this to final folder
        folderToRead = "/script/launch_deployment/";

        uint64[] memory chains = new uint64[](7);
        chains[0] = ETH;
        chains[1] = BSC;
        chains[2] = AVAX;
        chains[3] = POLY;
        chains[4] = ARBI;
        chains[5] = OP;
        chains[6] = BASE;

        TARGET_DEPLOYMENT_CHAINS = chains;

        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                     TESTS
    //////////////////////////////////////////////////////////////*/

    function test_superRegistryAddresses() public {
        SuperRegistry sr;

        uint256 len = 9;
        bytes32[] memory ids = new bytes32[](len);
        ids[0] = keccak256("PAYMENT_ADMIN");
        ids[1] = keccak256("CORE_REGISTRY_PROCESSOR");
        ids[2] = keccak256("BROADCAST_REGISTRY_PROCESSOR");
        ids[3] = keccak256("TIMELOCK_REGISTRY_PROCESSOR");
        ids[4] = keccak256("CORE_REGISTRY_UPDATER");
        ids[5] = keccak256("CORE_REGISTRY_RESCUER");
        ids[6] = keccak256("CORE_REGISTRY_DISPUTER");
        ids[7] = keccak256("DST_SWAPPER_PROCESSOR");
        ids[8] = keccak256("SUPERFORM_RECEIVER");

        address[] memory newAddresses = new address[](len);
        newAddresses[0] = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
        newAddresses[1] = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
        newAddresses[2] = EMERGENCY_ADMIN;
        newAddresses[3] = EMERGENCY_ADMIN;
        newAddresses[4] = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
        newAddresses[5] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
        newAddresses[6] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
        newAddresses[7] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
        newAddresses[8] = 0x1a6805487322565202848f239C1B5bC32303C2FE;
        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            vm.selectFork(FORKS[TARGET_DEPLOYMENT_CHAINS[i]]);
            sr = SuperRegistry(getContract(TARGET_DEPLOYMENT_CHAINS[i], "SuperRegistry"));

            for (uint256 j = 0; j < len; ++j) {
                assertEq(sr.getAddress(ids[j]), newAddresses[j]);
            }
        }
    }

    function test_superRegistryAddresses_destination() public {
        SuperRegistry sr;

        uint256 len = 18;
        bytes32[] memory ids = new bytes32[](len);
        ids[0] = keccak256("SUPERFORM_ROUTER");
        ids[1] = keccak256("SUPERFORM_FACTORY");
        ids[2] = keccak256("PAYMASTER");
        ids[3] = keccak256("PAYMENT_HELPER");
        ids[4] = keccak256("CORE_STATE_REGISTRY");
        ids[5] = keccak256("DST_SWAPPER");
        ids[6] = keccak256("SUPER_POSITIONS");
        ids[7] = keccak256("SUPER_RBAC");
        ids[8] = keccak256("PAYLOAD_HELPER");
        ids[9] = keccak256("EMERGENCY_QUEUE");
        ids[10] = keccak256("PAYMENT_ADMIN");
        ids[11] = keccak256("CORE_REGISTRY_PROCESSOR");
        ids[12] = keccak256("CORE_REGISTRY_UPDATER");
        ids[13] = keccak256("BROADCAST_REGISTRY_PROCESSOR");
        ids[14] = keccak256("CORE_REGISTRY_RESCUER");
        ids[15] = keccak256("CORE_REGISTRY_DISPUTER");
        ids[16] = keccak256("DST_SWAPPER_PROCESSOR");
        ids[17] = keccak256("SUPERFORM_RECEIVER");

        address[] memory newAddresses = new address[](len);

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            sr = SuperRegistry(getContract(chainId, "SuperRegistry"));

            newAddresses[0] = getContract(chainId, "SuperformRouter");
            newAddresses[1] = getContract(chainId, "SuperformFactory");
            newAddresses[2] = getContract(chainId, "PayMaster");
            newAddresses[3] = getContract(chainId, "PaymentHelper");
            newAddresses[4] = getContract(chainId, "CoreStateRegistry");
            newAddresses[5] = getContract(chainId, "DstSwapper");
            newAddresses[6] = getContract(chainId, "SuperPositions");
            newAddresses[7] = getContract(chainId, "SuperRBAC");
            newAddresses[8] = getContract(chainId, "PayloadHelper");
            newAddresses[9] = getContract(chainId, "EmergencyQueue");
            newAddresses[10] = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
            newAddresses[11] = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
            newAddresses[12] = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
            newAddresses[13] = EMERGENCY_ADMIN;
            newAddresses[14] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
            newAddresses[15] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
            newAddresses[16] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
            newAddresses[17] = 0x1a6805487322565202848f239C1B5bC32303C2FE;

            for (uint256 j = 0; j < len; ++j) {
                assertEq(sr.getAddress(ids[j]), newAddresses[j]);
            }
        }
    }

    function test_roles() public {
        SuperRBAC srbac;

        uint256 len = 11;

        bytes32[] memory ids = new bytes32[](len);

        ids[0] = keccak256("PROTOCOL_ADMIN_ROLE");
        ids[1] = keccak256("EMERGENCY_ADMIN_ROLE");
        ids[2] = keccak256("PAYMENT_ADMIN_ROLE");
        ids[3] = keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE");
        ids[4] = keccak256("TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE");
        ids[5] = keccak256("BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE");
        ids[6] = keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE");
        ids[7] = keccak256("DST_SWAPPER_ROLE");
        ids[8] = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
        ids[9] = keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE");
        ids[10] = keccak256("WORMHOLE_VAA_RELAYER_ROLE");

        address[] memory newAddresses = new address[](len);
        newAddresses[0] = 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92;
        newAddresses[1] = 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92;
        newAddresses[2] = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
        newAddresses[3] = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
        newAddresses[4] = EMERGENCY_ADMIN;
        newAddresses[5] = EMERGENCY_ADMIN;
        newAddresses[6] = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
        newAddresses[7] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
        newAddresses[8] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
        newAddresses[9] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
        newAddresses[10] = EMERGENCY_ADMIN;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            vm.selectFork(FORKS[TARGET_DEPLOYMENT_CHAINS[i]]);
            srbac = SuperRBAC(getContract(TARGET_DEPLOYMENT_CHAINS[i], "SuperRBAC"));

            for (uint256 j = 0; j < len; ++j) {
                assert(srbac.hasRole(ids[j], newAddresses[j]));
            }
            assert(srbac.hasRole(keccak256("PROTOCOL_ADMIN_ROLE"), PROTOCOL_ADMINS[i]));
            assert(srbac.hasRole(keccak256("EMERGENCY_ADMIN_ROLE"), EMERGENCY_ADMIN));
        }
    }

    function test_vaultLimitPerDst() public {
        SuperRegistry sr;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];

            vm.selectFork(FORKS[chainId]);
            sr = SuperRegistry(getContract(chainId, "SuperRegistry"));
            assertEq(sr.getVaultLimitPerDestination(chainId), 5);

            for (uint256 j = 0; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (TARGET_DEPLOYMENT_CHAINS[j] == chainId) {
                    continue;
                }

                assertEq(sr.getVaultLimitPerDestination(TARGET_DEPLOYMENT_CHAINS[j]), 5);
            }
        }
    }

    function test_delay() public {
        SuperRegistry sr;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];

            vm.selectFork(FORKS[chainId]);
            sr = SuperRegistry(getContract(chainId, "SuperRegistry"));
            assertEq(sr.delay(), 14_400);
        }
    }

    function test_quorum() public {
        SuperRegistry sr;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];

            vm.selectFork(FORKS[chainId]);
            sr = SuperRegistry(getContract(chainId, "SuperRegistry"));

            for (uint256 j = 0; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (TARGET_DEPLOYMENT_CHAINS[j] == chainId) {
                    continue;
                }

                assertEq(sr.getRequiredMessagingQuorum(TARGET_DEPLOYMENT_CHAINS[j]), 1);
            }
        }
    }

    function test_hopBlacklistSocket() public {
        SocketValidator sv;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            sv = SocketValidator(getContract(chainId, "SocketValidator"));

            if (chainId == 1) {
                // Mainnet Hop
                assert(sv.isRouteBlacklisted(18));
            } else if (chainId == 10) {
                // Optimism Hop
                assert(sv.isRouteBlacklisted(15));
            } else if (chainId == 42_161) {
                // Arbitrum hop
                assert(sv.isRouteBlacklisted(16));
            } else if (chainId == 137) {
                // Polygon hop
                assert(sv.isRouteBlacklisted(21));
            } else if (chainId == 8453) {
                // Base hop
                assert(sv.isRouteBlacklisted(1));
            }
        }
    }
}
