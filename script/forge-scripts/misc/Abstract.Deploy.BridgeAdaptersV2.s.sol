// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import "src/interfaces/ISuperRegistry.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
}

/// @dev deploys LayerzeroV2, Hyperlane (with amb protect) and Wormhole (with amb protect)
/// @dev on staging sets the new AMBs in super registry
abstract contract AbstractDeployBridgeAdaptersV2 is EnvironmentUtils {
    function _deployBridgeAdaptersV2(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        SetupVars memory vars;

        vars.chainId = s_superFormChainIds[i];
        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        address superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        address expectedSr = env == 0
            ? 0x17A332dC7B40aE701485023b219E9D6f493a2514
            : vars.chainId == 250 ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        vars.lzImplementation = address(new LayerzeroV2Implementation{ salt: salt }(ISuperRegistry(superRegistry)));
        contracts[vars.chainId][bytes32(bytes("LayerzeroImplementation"))] = vars.lzImplementation;

        /// @dev hyperlane does not exist on Fantom
        if (vars.chainId != 250) {
            vars.hyperlaneImplementation =
                address(new HyperlaneImplementation{ salt: salt }(ISuperRegistry(superRegistry)));
            contracts[vars.chainId][bytes32(bytes("HyperlaneImplementation"))] = vars.hyperlaneImplementation;
        }

        vars.wormholeImplementation = address(new WormholeARImplementation{ salt: salt }(ISuperRegistry(superRegistry)));
        contracts[vars.chainId][bytes32(bytes("WormholeARImplementation"))] = vars.wormholeImplementation;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addNewBridgeAdaptersSuperRegistryStaging(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        assert(env == 1);
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];
        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        if (vars.chainId != 250) {
            uint8[] memory bridgeIds = new uint8[](3);
            /// lz v2
            bridgeIds[0] = 14;
            /// hyperlane (with amb protect)
            bridgeIds[1] = 15;
            /// wormhole (with amb protect)
            bridgeIds[2] = 16;

            address[] memory bridgeAddress = new address[](3);
            bridgeAddress[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
            bridgeAddress[1] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "HyperlaneImplementation");
            bridgeAddress[2] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeARImplementation");

            assert(bridgeAddress[0] != address(0));
            assert(bridgeAddress[1] != address(0));
            assert(bridgeAddress[2] != address(0));

            vars.superRegistryC =
                SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
            address expectedSr = 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
            assert(address(vars.superRegistryC) == expectedSr);

            vars.superRegistryC.setAmbAddress(bridgeIds, bridgeAddress, new bool[](3));
        } else {
            uint8[] memory bridgeIds = new uint8[](2);
            /// lz v2
            bridgeIds[0] = 14;
            /// wormhole (with amb protect)
            bridgeIds[1] = 16;

            address[] memory bridgeAddress = new address[](2);
            bridgeAddress[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation");
            bridgeAddress[1] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeARImplementation");

            assert(bridgeAddress[0] != address(0));
            assert(bridgeAddress[1] != address(0));

            vars.superRegistryC =
                SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
            address expectedSr = 0x7B8d68f90dAaC67C577936d3Ce451801864EF189;
            assert(address(vars.superRegistryC) == expectedSr);

            vars.superRegistryC.setAmbAddress(bridgeIds, bridgeAddress, new bool[](2));
        }
        vm.stopBroadcast();
    }

    function _configureDeployedAdapters(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;
        vars.chainId = s_superFormChainIds[i];
        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        LayerzeroV2Implementation lzImpl = LayerzeroV2Implementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation")
        );
        HyperlaneImplementation hypImpl = HyperlaneImplementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "HyperlaneImplementation")
        );
        WormholeARImplementation wormholeImpl = WormholeARImplementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeARImplementation")
        );

        wormholeImpl.setRefundChainId(wormhole_chainIds[trueIndex]);

        lzImpl.setLzEndpoint(lzV2Endpoint);

        if (vars.chainId == 8453) {
            wormholeImpl.setWormholeRelayer(wormholeBaseRelayer);
        } else {
            wormholeImpl.setWormholeRelayer(wormholeRelayer);
        }

        if (vars.chainId != 250) {
            hypImpl.setHyperlaneConfig(
                IMailbox(hyperlaneMailboxes[trueIndex]), IInterchainGasPaymaster(hyperlanePaymasters[trueIndex])
            );
        }

        for (uint256 j; j < TARGET_CHAINS.length; j++) {
            vars.dstChainId = TARGET_CHAINS[j];
            if (vars.chainId != vars.dstChainId) {
                vars.dstTrueIndex = _getTrueIndex(vars.dstChainId);

                /// set chain ids
                lzImpl.setChainId(vars.dstChainId, lz_chainIds[vars.dstTrueIndex]);
                wormholeImpl.setChainId(vars.dstChainId, wormhole_chainIds[vars.dstTrueIndex]);

                /// set receivers
                lzImpl.setPeer(
                    lz_chainIds[vars.dstTrueIndex],
                    bytes32(
                        uint256(
                            uint160(
                                _readContractsV1(
                                    env, chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroImplementation"
                                )
                            )
                        )
                    )
                );

                wormholeImpl.setReceiver(
                    wormhole_chainIds[vars.dstTrueIndex],
                    _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "WormholeARImplementation")
                );

                if (vars.dstChainId != 250 && vars.chainId != 250) {
                    hypImpl.setChainId(vars.dstChainId, hyperlane_chainIds[vars.dstTrueIndex]);
                    hypImpl.setReceiver(
                        hyperlane_chainIds[vars.dstTrueIndex],
                        _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "HyperlaneImplementation")
                    );
                }
            }
        }

        vm.stopBroadcast();
    }

    function _getTrueIndex(uint256 chainId) public view returns (uint256 index) {
        for (uint256 i; i < chainIds.length; i++) {
            if (chainId == chainIds[i]) {
                index = i;
                break;
            }
        }
    }
}
