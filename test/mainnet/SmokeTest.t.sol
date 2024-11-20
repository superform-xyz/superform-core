// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/MainnetBaseSetup.sol";
import "forge-std/console.sol";
import "src/vendor/layerzero/v2/ILayerZeroEndpointV2.sol";

contract SmokeTest is MainnetBaseSetup {
    function setUp() public override {
        folderToRead = "/script/deployments/v1_deployment/";

        uint64[] memory chains = new uint64[](10);
        chains[0] = ETH;
        chains[1] = BSC;
        chains[2] = AVAX;
        chains[3] = POLY;
        chains[4] = ARBI;
        chains[5] = OP;
        chains[6] = BASE;
        chains[7] = FANTOM;
        chains[8] = LINEA;
        chains[9] = BLAST;

        TARGET_DEPLOYMENT_CHAINS = chains;
        EMERGENCY_ADMIN = 0x73009CE7cFFc6C4c5363734d1b429f0b848e0490;

        super.setUp();
    }

    /*///////////////////////////////////////////////////////////////
                     TESTS
    //////////////////////////////////////////////////////////////*/
    struct UlnConfig {
        uint64 confirmations;
        // we store the length of required DVNs and optional DVNs instead of using DVN.length directly to save gas
        uint8 requiredDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
        uint8 optionalDVNCount; // 0 indicate DEFAULT, NIL_DVN_COUNT indicate NONE (to override the value of default)
        uint8 optionalDVNThreshold; // (0, optionalDVNCount]
        address[] requiredDVNs; // no duplicates. sorted an an ascending order. allowed overlap with optionalDVNs
        address[] optionalDVNs; // no duplicates. sorted an an ascending order. allowed overlap with requiredDVNs
    }

    function test_lzConfig() public {
        bytes memory config;
        address oapp;

        ILayerZeroEndpointV2 endpoint = ILayerZeroEndpointV2(lzV2Endpoint);

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chain = TARGET_DEPLOYMENT_CHAINS[i];
            if (chain == BLAST) continue;
            vm.selectFork(FORKS[chain]);
            oapp = getContract(chain, "LayerzeroImplementation");
            for (uint256 j = 0; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                uint64 dstChain = TARGET_DEPLOYMENT_CHAINS[j];
                if (chain != dstChain && !(dstChain == LINEA || dstChain == BLAST)) {
                    config = endpoint.getConfig(oapp, lzV2SendLib[i], lz_v2_chainIds[j], 2);
                    UlnConfig memory ulnConfig = abi.decode(config, (UlnConfig));
                    assert(ulnConfig.confirmations == CONFIRMATIONS[chain][dstChain]);
                    for (uint256 k = 0; k < ulnConfig.requiredDVNs.length; k++) {
                        // Validate DVNs are properly ordered (ascending)
                        if (SuperformDVNs[i] < LzDVNs[i]) {
                            assert(ulnConfig.requiredDVNs[0] == SuperformDVNs[i]);
                            assert(ulnConfig.requiredDVNs[1] == LzDVNs[i]);
                        } else {
                            assert(ulnConfig.requiredDVNs[0] == LzDVNs[i]);
                            assert(ulnConfig.requiredDVNs[1] == SuperformDVNs[i]);
                        }
                    }
                }
            }
        }
    }

    function test_superRegistryAddresses() public {
        SuperRegistry sr;

        uint256 len = 10;
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
        ids[9] = keccak256("REWARDS_DISTRIBUTOR");

        address[] memory newAddresses = new address[](len);
        newAddresses[0] = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
        newAddresses[1] = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
        newAddresses[2] = 0x98616F52063d2A301be71386D381F43176A04F0f;
        newAddresses[3] = EMERGENCY_ADMIN;
        newAddresses[4] = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
        newAddresses[5] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
        newAddresses[6] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
        newAddresses[7] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
        newAddresses[8] = 0x1a6805487322565202848f239C1B5bC32303C2FE;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            vm.selectFork(FORKS[TARGET_DEPLOYMENT_CHAINS[i]]);

            if (TARGET_DEPLOYMENT_CHAINS[i] == FANTOM) {
                newAddresses[9] = 0xD6ceA5c8853c3fB4bbD77eF5E924c4e647c03a94;
            } else {
                newAddresses[9] = 0xce23bD7205bF2B543F6B4eeC00Add0C111FEFc3B;
            }
            sr = SuperRegistry(getContract(TARGET_DEPLOYMENT_CHAINS[i], "SuperRegistry"));

            for (uint256 j = 0; j < len; ++j) {
                assertEq(sr.getAddress(ids[j]), newAddresses[j]);
            }
        }
    }

    /*
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
            newAddresses[13] = 0x98616F52063d2A301be71386D381F43176A04F0f;
            newAddresses[14] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
            newAddresses[15] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
            newAddresses[16] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
            newAddresses[17] = 0x1a6805487322565202848f239C1B5bC32303C2FE;

            for (uint256 j = 0; j < len; ++j) {
                assertEq(sr.getAddress(ids[j]), newAddresses[j]);
            }
        }
    }
    */

    function test_roles() public {
        SuperRBAC srbac;

        uint256 len = 9;

        bytes32[] memory ids = new bytes32[](len);

        ids[0] = keccak256("PAYMENT_ADMIN_ROLE");
        ids[1] = keccak256("CORE_STATE_REGISTRY_PROCESSOR_ROLE");
        ids[2] = keccak256("TIMELOCK_STATE_REGISTRY_PROCESSOR_ROLE");
        ids[3] = keccak256("BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE");
        ids[4] = keccak256("CORE_STATE_REGISTRY_UPDATER_ROLE");
        ids[5] = keccak256("DST_SWAPPER_ROLE");
        ids[6] = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
        ids[7] = keccak256("CORE_STATE_REGISTRY_DISPUTER_ROLE");
        ids[8] = keccak256("WORMHOLE_VAA_RELAYER_ROLE");

        address[] memory newAddresses = new address[](len);
        newAddresses[0] = 0xD911673eAF0D3e15fe662D58De15511c5509bAbB;
        newAddresses[1] = 0x23c658FE050B4eAeB9401768bF5911D11621629c;
        newAddresses[2] = EMERGENCY_ADMIN;
        newAddresses[3] = 0x98616F52063d2A301be71386D381F43176A04F0f;
        newAddresses[4] = 0xaEbb4b9f7e16BEE2a0963569a5E33eE10E478a5f;
        newAddresses[5] = 0x1666660D2F506e754CB5c8E21BDedC7DdEc6Be1C;
        newAddresses[6] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
        newAddresses[7] = 0x7c9c8C0A9aA5D8a2c2e6C746641117Cc9591296a;
        newAddresses[8] = 0x1A86b5c1467331A3A52572663FDBf037A9e29719;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            srbac = SuperRBAC(getContract(chainId, "SuperRBAC"));

            for (uint256 j = 0; j < len; ++j) {
                assert(srbac.hasRole(ids[j], newAddresses[j]));
                /// @dev each role should have a single member
                assertEq(srbac.getRoleMemberCount(ids[j]), 1);
            }
            assert(srbac.hasRole(keccak256("PROTOCOL_ADMIN_ROLE"), PROTOCOL_ADMINS[i]));
            assert(srbac.hasRole(keccak256("EMERGENCY_ADMIN_ROLE"), EMERGENCY_ADMIN));

            assertEq(srbac.getRoleMemberCount(keccak256("PROTOCOL_ADMIN_ROLE")), 1);
            assertEq(srbac.getRoleMemberCount(keccak256("EMERGENCY_ADMIN_ROLE")), 1);
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
                console.log("chainId", chainId);
                console.log("TARGET_DEPLOYMENT_CHAINS[j]", TARGET_DEPLOYMENT_CHAINS[j]);

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
        mailboxes[7] = address(0);
        mailboxes[8] = 0x02d16BC51af6BfD153d67CA61754cF912E82C4d9;
        mailboxes[9] = 0x3a867fCfFeC2B790970eeBDC9023E75B0a172aa7;

        /// @dev index should match the index of target chains
        address[] memory igps = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        igps[0] = 0x9e6B1022bE9BBF5aFd152483DAD9b88911bC8611;
        igps[1] = 0x78E25e7f84416e69b9339B0A6336EB6EFfF6b451;
        igps[2] = 0x95519ba800BBd0d34eeAE026fEc620AD978176C0;
        igps[3] = 0x0071740Bf129b05C4684abfbBeD248D80971cce2;
        igps[4] = 0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22;
        igps[5] = 0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C;
        igps[6] = 0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94;
        igps[7] = address(0);
        igps[8] = 0x8105a095368f1a184CceA86cCe21318B5Ee5BE28;
        igps[9] = 0xB3fCcD379ad66CED0c91028520C64226611A48c9;

        /// @dev index should match the index of target chains
        uint32[] memory _ambIds = new uint32[](TARGET_DEPLOYMENT_CHAINS.length);
        _ambIds[0] = uint32(1);
        _ambIds[1] = uint32(56);
        _ambIds[2] = uint32(43_114);
        _ambIds[3] = uint32(137);
        _ambIds[4] = uint32(42_161);
        _ambIds[5] = uint32(10);
        _ambIds[6] = uint32(8453);
        _ambIds[7] = uint32(250);
        _ambIds[8] = uint32(59_144);
        _ambIds[9] = uint32(81_457);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            if (chainId != 250) {
                vm.selectFork(FORKS[chainId]);
                hyperlane = HyperlaneImplementation(getContract(chainId, "HyperlaneImplementation"));

                assertEq(address(hyperlane.mailbox()), mailboxes[i]);
                assertEq(address(hyperlane.igp()), igps[i]);

                for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                    if (chainId != TARGET_DEPLOYMENT_CHAINS[j] && TARGET_DEPLOYMENT_CHAINS[j] != 250) {
                        assertEq(
                            hyperlane.authorizedImpl(_ambIds[j]),
                            getContract(TARGET_DEPLOYMENT_CHAINS[j], "HyperlaneImplementation")
                        );
                        assertEq(hyperlane.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), _ambIds[j]);
                        assertEq(hyperlane.superChainId(_ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                    }
                }
            }
        }
    }

    function test_layerzeroImplementation() public {
        LayerzeroV2Implementation layerzero;

        /// @dev index should match the index of target chains
        address[] memory endpoints = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        endpoints[0] = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
        endpoints[1] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[2] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[3] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[4] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[5] = 0x3c2269811836af69497E5F486A85D7316753cf62;
        endpoints[6] = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
        endpoints[7] = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
        endpoints[8] = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
        endpoints[9] = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

        /// @dev index should match the index of target chains
        uint16[] memory _ambIds = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        _ambIds[0] = uint16(30_101);
        _ambIds[1] = uint16(30_102);
        _ambIds[2] = uint16(30_106);
        _ambIds[3] = uint16(30_109);
        _ambIds[4] = uint16(30_110);
        _ambIds[5] = uint16(30_111);
        _ambIds[6] = uint16(30_184);
        _ambIds[7] = uint16(30_112);
        _ambIds[8] = uint16(30_183);
        _ambIds[9] = uint16(30_243);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];

            vm.selectFork(FORKS[chainId]);
            layerzero = LayerzeroV2Implementation(getContract(chainId, "LayerzeroImplementation"));

            assertEq(address(layerzero.endpoint()), lzV2Endpoint);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        layerzero.peers(_ambIds[j]),
                        bytes32(uint256(uint160(getContract(TARGET_DEPLOYMENT_CHAINS[j], "LayerzeroImplementation"))))
                    );
                    assertEq(layerzero.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), _ambIds[j]);
                    assertEq(layerzero.superChainId(_ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
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
        relayers[7] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;
        relayers[8] = address(0);
        relayers[9] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;

        /// @dev index should match the index of target chains
        uint16[] memory _ambIds = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        _ambIds[0] = uint16(2);
        _ambIds[1] = uint16(4);
        _ambIds[2] = uint16(6);
        _ambIds[3] = uint16(5);
        _ambIds[4] = uint16(23);
        _ambIds[5] = uint16(24);
        _ambIds[6] = uint16(30);
        _ambIds[7] = uint16(10);
        _ambIds[8] = uint16(38);
        _ambIds[9] = uint16(36);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            if (chainId != LINEA) {
                vm.selectFork(FORKS[chainId]);
                wormhole = WormholeARImplementation(getContract(chainId, "WormholeARImplementation"));

                assertEq(address(wormhole.relayer()), relayers[i]);
                assertEq(wormhole.refundChainId(), _ambIds[i]);

                for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                    if (chainId != TARGET_DEPLOYMENT_CHAINS[j] && TARGET_DEPLOYMENT_CHAINS[j] != LINEA) {
                        assertEq(
                            wormhole.authorizedImpl(_ambIds[j]),
                            getContract(TARGET_DEPLOYMENT_CHAINS[j], "WormholeARImplementation")
                        );
                        assertEq(wormhole.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), _ambIds[j]);
                        assertEq(wormhole.superChainId(_ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                    }
                }
            }
        }
    }

    function test_wormholeSRImplementation() public {
        WormholeSRImplementation wormhole;

        /// @dev index should match the index of target chains
        address[] memory _wormholeCore = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        _wormholeCore[0] = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
        _wormholeCore[1] = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
        _wormholeCore[2] = 0x54a8e5f9c4CbA08F9943965859F6c34eAF03E26c;
        _wormholeCore[3] = 0x7A4B5a56256163F07b2C80A7cA55aBE66c4ec4d7;
        _wormholeCore[4] = 0xa5f208e072434bC67592E4C49C1B991BA79BCA46;
        _wormholeCore[5] = 0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722;
        _wormholeCore[6] = 0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6;
        _wormholeCore[7] = 0x126783A6Cb203a3E35344528B26ca3a0489a1485;
        _wormholeCore[8] = address(0);
        _wormholeCore[9] = 0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6;

        /// @dev index should match the index of target chains
        uint16[] memory _ambIds = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        _ambIds[0] = uint16(2);
        _ambIds[1] = uint16(4);
        _ambIds[2] = uint16(6);
        _ambIds[3] = uint16(5);
        _ambIds[4] = uint16(23);
        _ambIds[5] = uint16(24);
        _ambIds[6] = uint16(30);
        _ambIds[7] = uint16(10);
        _ambIds[8] = uint16(38);
        _ambIds[9] = uint16(36);

        address relayer = 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92;

        /// owner address for now

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            if (chainId != LINEA) {
                wormhole = WormholeSRImplementation(getContract(chainId, "WormholeSRImplementation"));

                assertEq(address(wormhole.relayer()), relayer);
                assertEq(address(wormhole.wormhole()), _wormholeCore[i]);
                assertEq(wormhole.broadcastFinality(), 0);

                for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                    if (chainId != TARGET_DEPLOYMENT_CHAINS[j] && TARGET_DEPLOYMENT_CHAINS[j] != LINEA) {
                        assertEq(
                            wormhole.authorizedImpl(_ambIds[j]),
                            getContract(TARGET_DEPLOYMENT_CHAINS[j], "WormholeSRImplementation")
                        );
                        assertEq(wormhole.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), _ambIds[j]);
                        assertEq(wormhole.superChainId(_ambIds[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                    }
                }
            }
        }
    }

    function test_axelarImplementation() public {
        AxelarImplementation axelar;

        /// @dev index should match the index of target chains
        address[] memory axelar_gateways = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        axelar_gateways[0] = 0x4F4495243837681061C4743b74B3eEdf548D56A5;
        axelar_gateways[1] = 0x304acf330bbE08d1e512eefaa92F6a57871fD895;
        axelar_gateways[2] = 0x5029C0EFf6C34351a0CEc334542cDb22c7928f78;
        axelar_gateways[3] = 0x6f015F16De9fC8791b234eF68D486d2bF203FBA8;
        axelar_gateways[4] = 0xe432150cce91c13a887f7D836923d5597adD8E31;
        axelar_gateways[5] = 0xe432150cce91c13a887f7D836923d5597adD8E31;
        axelar_gateways[6] = 0xe432150cce91c13a887f7D836923d5597adD8E31;
        axelar_gateways[7] = 0x304acf330bbE08d1e512eefaa92F6a57871fD895;
        axelar_gateways[8] = 0xe432150cce91c13a887f7D836923d5597adD8E31;
        axelar_gateways[9] = 0xe432150cce91c13a887f7D836923d5597adD8E31;

        /// @dev index should match the index of target chains
        address[] memory axelar_gasServices = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        axelar_gasServices[0] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[1] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[2] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[3] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[4] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[5] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[6] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[7] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[8] = 0x2d5d7d31F671F86C782533cc367F14109a082712;
        axelar_gasServices[9] = 0x2d5d7d31F671F86C782533cc367F14109a082712;

        /// @dev index should match the index of target chains
        string[] memory ambIds_ = new string[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds_[0] = "Ethereum";
        ambIds_[1] = "binance";
        ambIds_[2] = "Avalanche";
        ambIds_[3] = "Polygon";
        ambIds_[4] = "arbitrum";
        ambIds_[5] = "optimism";
        ambIds_[6] = "base";
        ambIds_[7] = "Fantom";
        ambIds_[8] = "linea";
        ambIds_[9] = "blast";

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            axelar = AxelarImplementation(getContract(chainId, "AxelarImplementation"));

            assertEq(address(axelar.gateway()), axelar_gateways[i]);
            assertEq(address(axelar.gasService()), axelar_gasServices[i]);
            assertEq(address(axelar.gasEstimator()), axelar_gasServices[i]);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    if (TARGET_DEPLOYMENT_CHAINS[j] == LINEA || TARGET_DEPLOYMENT_CHAINS[j] == BLAST) {
                        assertEq(
                            axelar.authorizedImpl(ambIds_[j]),
                            chainId == LINEA || chainId == BLAST ? address(0xDEAD) : address(0)
                        );
                        assertEq(
                            axelar.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]),
                            chainId == LINEA ? "blast" : chainId == BLAST ? "linea" : ""
                        );
                        assertEq(
                            axelar.superChainId(ambIds_[j]), chainId == LINEA ? 81_457 : chainId == BLAST ? 59_144 : 0
                        );
                    } else {
                        assertEq(axelar.authorizedImpl(ambIds_[j]), address(0xDEAD));
                        assertEq(axelar.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds_[j]);
                        assertEq(axelar.superChainId(ambIds_[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                    }
                }
            }
        }
    }

    function test_deBridgeValidators() public {
        SuperRegistry superRegistry;

        address de_bridge_address = 0xeF4fB24aD0916217251F553c0596F8Edc630EB66;
        address de_bridge_forwarder_address = 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251;

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            if (chainId == FANTOM || chainId == BLAST) continue;

            vm.selectFork(FORKS[chainId]);
            superRegistry = SuperRegistry(getContract(chainId, "SuperRegistry"));

            assertEq(superRegistry.getBridgeValidator(5), getContract(chainId, "DeBridgeValidator"));
            assertEq(superRegistry.getBridgeValidator(6), getContract(chainId, "DeBridgeForwarderValidator"));

            assertEq(superRegistry.getBridgeAddress(5), de_bridge_address);
            assertEq(superRegistry.getBridgeAddress(6), de_bridge_forwarder_address);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                /// RESCUER role not set on other chains based on linea or blast as we're not using broadcaster
                if (TARGET_DEPLOYMENT_CHAINS[j] == LINEA || TARGET_DEPLOYMENT_CHAINS[j] == BLAST) {
                    continue;
                }
                assertEq(
                    superRegistry.getAddressByChainId(
                        keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), TARGET_DEPLOYMENT_CHAINS[j]
                    ),
                    0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5
                );
            }
        }
    }

    function test_oneInchValidator() public {
        SuperRegistry superRegistry;

        address one_inch_address = 0x111111125421cA6dc452d289314280a0f8842A65;

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            if (chainId == FANTOM || chainId == LINEA || chainId == BLAST) continue;

            vm.selectFork(FORKS[chainId]);
            superRegistry = SuperRegistry(getContract(chainId, "SuperRegistry"));

            assertEq(superRegistry.getBridgeValidator(4), getContract(chainId, "OneInchValidator"));
            assertEq(superRegistry.getBridgeAddress(4), one_inch_address);
        }
    }

    function test_paymentHelper() public {
        PaymentHelper paymentHelper;

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            paymentHelper = PaymentHelper(getContract(chainId, "PaymentHelper"));

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                assertEq(
                    address(paymentHelper.nativeFeedOracle(TARGET_DEPLOYMENT_CHAINS[j])),
                    PRICE_FEEDS[chainId][TARGET_DEPLOYMENT_CHAINS[j]]
                );
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        paymentHelper.swapGasUsed(TARGET_DEPLOYMENT_CHAINS[j]),
                        abi.decode(GAS_USED[TARGET_DEPLOYMENT_CHAINS[j]][3], (uint256))
                    );
                    assertEq(
                        paymentHelper.updateDepositGasUsed(TARGET_DEPLOYMENT_CHAINS[j]),
                        abi.decode(GAS_USED[TARGET_DEPLOYMENT_CHAINS[j]][4], (uint256))
                    );

                    assertEq(
                        paymentHelper.withdrawGasUsed(TARGET_DEPLOYMENT_CHAINS[j]),
                        abi.decode(GAS_USED[TARGET_DEPLOYMENT_CHAINS[j]][6], (uint256))
                    );
                }
            }
        }
    }

    function test_rewardsDistributor() public {
        RewardsDistributor rewardsDistributor;
        SuperRegistry superRegistry;
        SuperRBAC superRBAC;

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            rewardsDistributor = RewardsDistributor(getContract(chainId, "RewardsDistributor"));
            superRegistry = SuperRegistry(getContract(chainId, "SuperRegistry"));
            superRBAC = SuperRBAC(getContract(chainId, "SuperRBAC"));

            assertEq(superRBAC.getRoleAdmin(keccak256("REWARDS_ADMIN_ROLE")), superRBAC.PROTOCOL_ADMIN_ROLE());
            assertTrue(superRBAC.hasRole(keccak256("REWARDS_ADMIN_ROLE"), REWARDS_ADMIN));

            assertEq(address(rewardsDistributor.superRegistry()), address(superRegistry));
        }
    }
}
