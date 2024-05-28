// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "test/utils/MainnetBaseSetup.sol";

contract SmokeTestStaging is MainnetBaseSetup {
    function setUp() public override {
        folderToRead = "/script/deployments/v1_staging_deployment/";

        uint64[] memory chains = new uint64[](5);
        chains[0] = BSC;
        chains[1] = ARBI;
        chains[2] = OP;
        chains[3] = BASE;
        chains[4] = FANTOM;

        TARGET_DEPLOYMENT_CHAINS = chains;
        EMERGENCY_ADMIN = 0x6A5DD913fE3CB5193E09D1810a3b9ff1C0f9c0D6;

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
        newAddresses[0] = 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3;
        newAddresses[1] = 0x2759142A9e3cBbcCc1E3d5F76490eEE4007B8943;
        newAddresses[2] = 0x65c2d7e8d31C845894491ABe5789Ba1e5d4382fC;
        newAddresses[3] = EMERGENCY_ADMIN;
        newAddresses[4] = 0xF1c73958118F22Fc3A3947f405DcEBF08a1E68f7;
        newAddresses[5] = 0xe1A61d90554131314cB30dB55B8AD4F4b6e21C3a;
        newAddresses[6] = 0xe9F074d003b377A197D336B8a1c86EdaA6cC4dEF;
        newAddresses[7] = 0x3ea519270248BdEE4a939df20049E02290bf9CaF;
        newAddresses[8] = 0x46F15EDC21f7eed6D1eb01e5Abe993Dc6c6A78BB;
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
            newAddresses[10] = 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3;
            newAddresses[11] = 0x2759142A9e3cBbcCc1E3d5F76490eEE4007B8943;
            newAddresses[12] = 0xF1c73958118F22Fc3A3947f405DcEBF08a1E68f7;
            newAddresses[13] = 0x65c2d7e8d31C845894491ABe5789Ba1e5d4382fC;
            newAddresses[14] = 0xe1A61d90554131314cB30dB55B8AD4F4b6e21C3a;
            newAddresses[15] = 0xe9F074d003b377A197D336B8a1c86EdaA6cC4dEF;
            newAddresses[16] = 0x3ea519270248BdEE4a939df20049E02290bf9CaF;
            newAddresses[17] = 0x46F15EDC21f7eed6D1eb01e5Abe993Dc6c6A78BB;

            for (uint256 j = 0; j < len; ++j) {
                assertEq(sr.getAddress(ids[j]), newAddresses[j]);
            }
        }
    }

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
        newAddresses[0] = 0xc5c971e6B9F01dcf06bda896AEA3648eD6e3EFb3;
        newAddresses[1] = 0x2759142A9e3cBbcCc1E3d5F76490eEE4007B8943;
        newAddresses[2] = EMERGENCY_ADMIN;
        newAddresses[3] = 0x65c2d7e8d31C845894491ABe5789Ba1e5d4382fC;
        newAddresses[4] = 0xF1c73958118F22Fc3A3947f405DcEBF08a1E68f7;
        newAddresses[5] = 0x3ea519270248BdEE4a939df20049E02290bf9CaF;
        newAddresses[6] = 0xe1A61d90554131314cB30dB55B8AD4F4b6e21C3a;
        newAddresses[7] = 0xe9F074d003b377A197D336B8a1c86EdaA6cC4dEF;
        newAddresses[8] = 0xaD1bF3301971Ecd9E6219423129e360774ABEA68;

        for (uint256 i = 0; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            srbac = SuperRBAC(getContract(chainId, "SuperRBAC"));

            for (uint256 j = 0; j < len; ++j) {
                assert(srbac.hasRole(ids[j], newAddresses[j]));
                if (chainId == 250 && ids[j] == keccak256("PAYMENT_ADMIN_ROLE")) {
                    assertEq(srbac.getRoleMemberCount(ids[j]), 2);
                } else {
                    /// @dev each role should have a single member
                    assertEq(srbac.getRoleMemberCount(ids[j]), 1);
                }
            }
            assert(srbac.hasRole(keccak256("PROTOCOL_ADMIN_ROLE"), 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92));
            assert(srbac.hasRole(keccak256("PROTOCOL_ADMIN_ROLE"), PROTOCOL_ADMINS_STAGING[i]));

            //assert(srbac.hasRole(keccak256("EMERGENCY_ADMIN_ROLE"), EMERGENCY_ADMIN));
            assertEq(srbac.getRoleMemberCount(keccak256("PROTOCOL_ADMIN_ROLE")), 2);
            assertEq(srbac.getRoleMemberCount(keccak256("EMERGENCY_ADMIN_ROLE")), 2);
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
            assertEq(sr.delay(), 900);
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
        mailboxes[0] = 0x2971b9Aec44bE4eb673DF1B88cDB57b96eefe8a4;
        mailboxes[1] = 0x979Ca5202784112f4738403dBec5D0F3B9daabB9;
        mailboxes[2] = 0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D;
        mailboxes[3] = 0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D;
        mailboxes[4] = address(0);

        /// @dev index should match the index of target chains
        address[] memory igps = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        igps[0] = 0x78E25e7f84416e69b9339B0A6336EB6EFfF6b451;
        igps[1] = 0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22;
        igps[2] = 0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C;
        igps[3] = 0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94;
        igps[4] = address(0);

        /// @dev index should match the index of target chains
        uint32[] memory ambIds_ = new uint32[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds_[0] = uint32(56);
        ambIds_[1] = uint32(42_161);
        ambIds_[2] = uint32(10);
        ambIds_[3] = uint32(8453);
        ambIds_[4] = uint32(250);

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
                            hyperlane.authorizedImpl(ambIds_[j]),
                            getContract(TARGET_DEPLOYMENT_CHAINS[j], "HyperlaneImplementation")
                        );
                        assertEq(hyperlane.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds_[j]);
                        assertEq(hyperlane.superChainId(ambIds_[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                    }
                }
            }
        }
    }

    function test_layerzeroImplementation() public {
        LayerzeroV2Implementation layerzero;

        /// @dev index should match the index of target chains
        uint32[] memory ambIds_ = new uint32[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds_[0] = uint16(30_102);
        ambIds_[1] = uint16(30_110);
        ambIds_[2] = uint16(30_111);
        ambIds_[3] = uint16(30_184);
        ambIds_[4] = uint16(30_112);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            layerzero = LayerzeroV2Implementation(getContract(chainId, "LayerzeroImplementation"));

            assertEq(address(layerzero.endpoint()), lzV2Endpoint);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        layerzero.peers(ambIds_[j]),
                        bytes32(uint256(uint160(getContract(TARGET_DEPLOYMENT_CHAINS[j], "LayerzeroImplementation"))))
                    );
                    assertEq(layerzero.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds_[j]);
                    assertEq(layerzero.superChainId(ambIds_[j]), TARGET_DEPLOYMENT_CHAINS[j]);
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
        relayers[3] = 0x706F82e9bb5b0813501714Ab5974216704980e31;
        relayers[4] = 0x27428DD2d3DD32A4D7f7C497eAaa23130d894911;

        /// @dev index should match the index of target chains
        uint16[] memory ambIds_ = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds_[0] = uint16(4);
        ambIds_[1] = uint16(23);
        ambIds_[2] = uint16(24);
        ambIds_[3] = uint16(30);
        ambIds_[4] = uint16(10);

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            wormhole = WormholeARImplementation(getContract(chainId, "WormholeARImplementation"));

            assertEq(address(wormhole.relayer()), relayers[i]);
            assertEq(wormhole.refundChainId(), ambIds_[i]);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        wormhole.authorizedImpl(ambIds_[j]),
                        getContract(TARGET_DEPLOYMENT_CHAINS[j], "WormholeARImplementation")
                    );
                    assertEq(wormhole.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds_[j]);
                    assertEq(wormhole.superChainId(ambIds_[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                }
            }
        }
    }

    function test_wormholeSRImplementation() public {
        WormholeSRImplementation wormhole;

        /// @dev index should match the index of target chains
        address[] memory wormholeCoreAddresses = new address[](TARGET_DEPLOYMENT_CHAINS.length);
        wormholeCoreAddresses[0] = 0x98f3c9e6E3fAce36bAAd05FE09d375Ef1464288B;
        wormholeCoreAddresses[1] = 0xa5f208e072434bC67592E4C49C1B991BA79BCA46;
        wormholeCoreAddresses[2] = 0xEe91C335eab126dF5fDB3797EA9d6aD93aeC9722;
        wormholeCoreAddresses[3] = 0xbebdb6C8ddC678FfA9f8748f85C815C556Dd8ac6;
        wormholeCoreAddresses[4] = 0x126783A6Cb203a3E35344528B26ca3a0489a1485;

        /// @dev index should match the index of target chains
        uint16[] memory ambIds_ = new uint16[](TARGET_DEPLOYMENT_CHAINS.length);
        ambIds_[0] = uint16(4);
        ambIds_[1] = uint16(23);
        ambIds_[2] = uint16(24);
        ambIds_[3] = uint16(30);
        ambIds_[4] = uint16(10);

        address relayer = 0x48aB8AdF869Ba9902Ad483FB1Ca2eFDAb6eabe92;

        /// owner address for now

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            wormhole = WormholeSRImplementation(getContract(chainId, "WormholeSRImplementation"));

            assertEq(address(wormhole.relayer()), relayer);
            assertEq(address(wormhole.wormhole()), wormholeCoreAddresses[i]);
            assertEq(wormhole.broadcastFinality(), 0);

            for (uint256 j; j < TARGET_DEPLOYMENT_CHAINS.length; ++j) {
                if (chainId != TARGET_DEPLOYMENT_CHAINS[j]) {
                    assertEq(
                        wormhole.authorizedImpl(ambIds_[j]),
                        getContract(TARGET_DEPLOYMENT_CHAINS[j], "WormholeSRImplementation")
                    );
                    assertEq(wormhole.ambChainId(TARGET_DEPLOYMENT_CHAINS[j]), ambIds_[j]);
                    assertEq(wormhole.superChainId(ambIds_[j]), TARGET_DEPLOYMENT_CHAINS[j]);
                }
            }
        }
    }

    function test_paymentHelper() public {
        PaymentHelper paymentHelper;

        for (uint256 i; i < TARGET_DEPLOYMENT_CHAINS.length; ++i) {
            uint64 chainId = TARGET_DEPLOYMENT_CHAINS[i];
            vm.selectFork(FORKS[chainId]);
            paymentHelper = PaymentHelper(getContract(chainId, "PaymentHelper"));
            console.log("--Checking chain id ", chainId);

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
}
