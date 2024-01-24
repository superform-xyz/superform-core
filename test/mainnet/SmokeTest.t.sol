// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/MainnetBaseSetup.sol";

contract SmokeTest is MainnetBaseSetup {
    function setUp() public override {
        folderToRead = "/script/v1_deployment/";

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

    function test_hyperlaneImplementation() public {
        HyperlaneImplementation hyperlane;

        /// @dev index should match the index of target chains
        address[] memory mailboxes = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        mailboxes[0] = 0xc005dc82818d67AF737725bD4bf75435d065D239;
        mailboxes[1] = 0x2971b9Aec44bE4eb673DF1B88cDB57b96eefe8a4;
        mailboxes[2] = 0xFf06aFcaABaDDd1fb08371f9ccA15D73D51FeBD6;
        mailboxes[3] = 0x5d934f4e2f797775e53561bB72aca21ba36B96BB;
        mailboxes[4] = 0x979Ca5202784112f4738403dBec5D0F3B9daabB9;
        mailboxes[5] = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D;
        mailboxes[6] = 0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D;

        /// @dev index should match the index of target chains
        address[] memory igps = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        igps[0] = 0x9e6B1022bE9BBF5aFd152483DAD9b88911bC8611;
        igps[1] = 0x78E25e7f84416e69b9339B0A6336EB6EFfF6b451;
        igps[2] = 0x95519ba800BBd0d34eeAE026fEc620AD978176C0;
        igps[3] = 0x0071740Bf129b05C4684abfbBeD248D80971cce2;
        igps[4] = 0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22;
        igps[5] = 0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C;
        igps[6] = 0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94;

        /// @dev index should match the index of target chains
        uint32[] memory ambIds = new uint32[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds[0] = uint32(1);
        ambIds[1] = uint32(56);
        ambIds[2] = uint32(43_114);
        ambIds[3] = uint32(137);
        ambIds[4] = uint32(42_161);
        ambIds[5] = uint32(10);
        ambIds[6] = uint32(8453);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            hyperlane = HyperlaneImplementation(getContract(chainId, "HyperlaneImplementation"));

            assertEq(address(hyperlane.mailbox()), mailboxes[i]);
            assertEq(address(hyperlane.igp()), igps[i]);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        hyperlane.authorizedImpl(ambIds[j]),
                        getContract(TARGET_DEPLOYMENT_CHAINS[j], "HyperlaneImplementation")
                    );
                    assertEq(hyperlane.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds[j]);
                    assertEq(hyperlane.superChainId(ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                }
            }
        }
    }

    function test_layerzeroImplementation() public {
        LayerzeroImplementation layerzero;

        /// @dev index should match the index of target chains
        address[] memory endpoints = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        endpoints[0] = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
        endpoints[1] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[2] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[3] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[4] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[5] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[6] = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

        /// @dev index should match the index of target chains
        uint16[] memory ambIds = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds[0] = uint16(101);
        ambIds[1] = uint16(102);
        ambIds[2] = uint16(106);
        ambIds[3] = uint16(109);
        ambIds[4] = uint16(110);
        ambIds[5] = uint16(111);
        ambIds[6] = uint16(184);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            layerzero = LayerzeroImplementation(getContract(chainId, "LayerzeroImplementation"));

            assertEq(address(layerzero.lzEndpoint()), endpoints[i]);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        layerzero.trustedRemoteLookup(ambIds[j]),
                        abi.encodePacked(
                            getContract(TARGET_DEPLOYMENT_CHAINS[j], "LayerzeroImplementation"),
                            getContract(TARGET_DEPLOYMENT_CHAINS[i], "LayerzeroImplementation")
                        )
                    );
                    assertEq(layerzero.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds[j]);
                    assertEq(layerzero.superChainId(ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                }
            }
        }
    }

    function test_wormholeARImplementation() public {
        WormholeARImplementation wormhole;

        /// @dev index should match the index of target chains
        address[] memory relayers = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        relayers[0] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[1] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[2] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[3] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[4] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[5] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[6] = 0x706F82e9bb5b0813501714Ab5974216704980e31;

        /// @dev index should match the index of target chains
        uint16[] memory ambIds = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds[0] = uint16(2);
        ambIds[1] = uint16(4);
        ambIds[2] = uint16(6);
        ambIds[3] = uint16(5);
        ambIds[4] = uint16(23);
        ambIds[5] = uint16(24);
        ambIds[6] = uint16(30);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            wormhole = WormholeARImplementation(getContract(chainId, "WormholeARImplementation"));

            assertEq(address(wormhole.relayer()), relayers[i]);
            assertEq(wormhole.refundChainId(), ambIds[i]);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        wormhole.authorizedImpl(ambIds[j]),
                        getContract(TARGET_DEPLOYMENT_CHAINS[j], "WormholeARImplementation")
                    );
                    assertEq(wormhole.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds[j]);
                    assertEq(wormhole.superChainId(ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                }
            }
        }
    }

    function test_wormholeSRImplementation() public {
        WormholeSRImplementation wormhole;

        /// @dev index should match the index of target chains
        address[] memory wormholeCore = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        wormholeCore[0] = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
        wormholeCore[1] = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
        wormholeCore[2] = 0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c;
        wormholeCore[3] = 0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7;
        wormholeCore[4] = 0xa5f208e072434bC67592E4C49C1B991BA79BCA46;
        wormholeCore[5] = 0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722;
        wormholeCore[6] = 0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6;

        /// @dev index should match the index of target chains
        uint16[] memory ambIds = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds[0] = uint16(2);
        ambIds[1] = uint16(4);
        ambIds[2] = uint16(6);
        ambIds[3] = uint16(5);
        ambIds[4] = uint16(23);
        ambIds[5] = uint16(24);
        ambIds[6] = uint16(30);

        address relayer = 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92;

        /// owner address for now

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            wormhole = WormholeSRImplementation(getContract(chainId, "WormholeSRImplementation"));

            assertEq(address(wormhole.relayer()), relayer);
            assertEq(address(wormhole.wormhole()), wormholeCore[i]);
            assertEq(wormhole.broadcastFinality(), 0);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        wormhole.authorizedImpl(ambIds[j]),
                        getContract(TARGET_DEPLOYMENT_CHAINS[j], "WormholeSRImplementation")
                    );
                    assertEq(wormhole.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds[j]);
                    assertEq(wormhole.superChainId(ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                }
            }
        }
    }
}
