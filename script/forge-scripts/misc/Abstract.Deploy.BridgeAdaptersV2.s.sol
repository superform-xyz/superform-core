// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import "src/interfaces/ISuperRegistry.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
    LayerzeroV2Implementation lzImpl;
    HyperlaneImplementation hypImpl;
    WormholeARImplementation wormholeImpl;
    AxelarImplementation axelarImpl;
    uint8[] bridgeIds;
    address[] bridgeAddress;
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
        address expectedSr;

        if (env == 0) {
            expectedSr = vars.chainId == 250
                ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
                : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        } else {
            expectedSr = vars.chainId == 250
                ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189
                : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        }
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
        if (env == 0) _configureDeployedAdaptersProd(env, i, trueIndex, cycle, s_superFormChainIds);
        if (env == 1) _configureDeployedAdaptersStaging(env, i, trueIndex, cycle, s_superFormChainIds);
    }

    function _configureDeployedAdaptersProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
    {
        assert(env == 0);
        assert(salt.length > 0);
        UpdateVars memory vars;
        vars.chainId = s_superFormChainIds[i];
        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        assert(address(vars.superRegistryC) == expectedSr);

        vars.lzImpl = LayerzeroV2Implementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroImplementation")
        );
        vars.hypImpl = HyperlaneImplementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "HyperlaneImplementation")
        );
        vars.wormholeImpl = WormholeARImplementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "WormholeARImplementation")
        );
        vars.axelarImpl =
            AxelarImplementation(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation"));

        bytes memory txn;
        if (vars.chainId != 250) {
            vars.bridgeIds = new uint8[](4);
            vars.bridgeIds[0] = 5; // layerzero-v2
            vars.bridgeIds[1] = 6; // hyperlane
            vars.bridgeIds[2] = 7; // wormhole-ar
            vars.bridgeIds[3] = 8; // axelar

            vars.bridgeAddress = new address[](4);
            vars.bridgeAddress[0] = address(vars.lzImpl);
            vars.bridgeAddress[1] = address(vars.hypImpl);
            vars.bridgeAddress[2] = address(vars.wormholeImpl);
            vars.bridgeAddress[3] = address(vars.axelarImpl);

            assert(vars.bridgeAddress[0] != address(0));
            assert(vars.bridgeAddress[1] != address(0));
            assert(vars.bridgeAddress[2] != address(0));
            assert(vars.bridgeAddress[3] != address(0));

            txn = abi.encodeWithSelector(
                SuperRegistry.setAmbAddress.selector, vars.bridgeIds, vars.bridgeAddress, new bool[](4)
            );
            addToBatch(address(vars.superRegistryC), 0, txn);
        } else {
            vars.bridgeIds = new uint8[](3);
            vars.bridgeIds[0] = 5; // layerzero-v2
            vars.bridgeIds[1] = 7; // wormhole-ar
            vars.bridgeIds[2] = 8; // axelar

            vars.bridgeAddress = new address[](3);
            vars.bridgeAddress[0] = address(vars.lzImpl);
            vars.bridgeAddress[1] = address(vars.wormholeImpl);
            vars.bridgeAddress[2] = address(vars.axelarImpl);

            assert(vars.bridgeAddress[0] != address(0));
            assert(vars.bridgeAddress[1] != address(0));
            assert(vars.bridgeAddress[2] != address(0));

            txn = abi.encodeWithSelector(
                SuperRegistry.setAmbAddress.selector, vars.bridgeIds, vars.bridgeAddress, new bool[](3)
            );
            addToBatch(address(vars.superRegistryC), 0, txn);
        }

        txn = abi.encodeWithSelector(WormholeARImplementation.setRefundChainId.selector, wormhole_chainIds[trueIndex]);
        addToBatch(address(vars.wormholeImpl), 0, txn);

        assert(lzV2Endpoint != address(0));
        txn = abi.encodeWithSelector(LayerzeroV2Implementation.setLzEndpoint.selector, lzV2Endpoint);
        addToBatch(address(vars.lzImpl), 0, txn);

        if (vars.chainId == 8453) {
            assert(wormholeBaseRelayer != address(0));

            txn = abi.encodeWithSelector(WormholeARImplementation.setWormholeRelayer.selector, wormholeBaseRelayer);
            addToBatch(address(vars.wormholeImpl), 0, txn);
        } else {
            assert(wormholeRelayer != address(0));

            txn = abi.encodeWithSelector(WormholeARImplementation.setWormholeRelayer.selector, wormholeRelayer);
            addToBatch(address(vars.wormholeImpl), 0, txn);
        }

        if (vars.chainId != 250) {
            assert(trueIndex < hyperlaneMailboxes.length && trueIndex < hyperlanePaymasters.length);
            assert(hyperlaneMailboxes[trueIndex] != address(0) && hyperlanePaymasters[trueIndex] != address(0));

            txn = abi.encodeWithSelector(
                HyperlaneImplementation.setHyperlaneConfig.selector,
                IMailbox(hyperlaneMailboxes[trueIndex]),
                IInterchainGasPaymaster(hyperlanePaymasters[trueIndex])
            );
            addToBatch(address(vars.hypImpl), 0, txn);
        }

        assert(trueIndex < axelarGateway.length);
        assert(axelarGateway[trueIndex] != address(0));
        txn = abi.encodeWithSelector(
            AxelarImplementation.setAxelarConfig.selector, IAxelarGateway(axelarGateway[trueIndex])
        );
        addToBatch(address(vars.axelarImpl), 0, txn);

        assert(trueIndex < axelarGasService.length);
        assert(axelarGasService[trueIndex] != address(0));
        txn = abi.encodeWithSelector(
            AxelarImplementation.setAxelarGasService.selector,
            IAxelarGasService(axelarGasService[trueIndex]),
            IInterchainGasEstimation(axelarGasService[trueIndex])
        );
        addToBatch(address(vars.axelarImpl), 0, txn);

        for (uint256 j; j < TARGET_CHAINS.length; j++) {
            vars.dstChainId = TARGET_CHAINS[j];
            if (vars.chainId != vars.dstChainId) {
                vars.dstTrueIndex = _getTrueIndex(vars.dstChainId);

                // Assert that the destination true index is valid
                assert(vars.dstTrueIndex < chainIds.length);

                // Assert that all necessary arrays have sufficient length
                assert(vars.dstTrueIndex < lz_chainIds.length);
                assert(vars.dstTrueIndex < wormhole_chainIds.length);
                assert(vars.dstTrueIndex < axelar_chainIds.length);

                /// set chain ids
                txn = abi.encodeWithSelector(
                    LayerzeroV2Implementation.setChainId.selector, vars.dstChainId, lz_chainIds[vars.dstTrueIndex]
                );
                addToBatch(address(vars.lzImpl), 0, txn);

                txn = abi.encodeWithSelector(
                    WormholeARImplementation.setChainId.selector, vars.dstChainId, wormhole_chainIds[vars.dstTrueIndex]
                );
                addToBatch(address(vars.wormholeImpl), 0, txn);

                address dstLzImpl =
                    _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroImplementation");
                assert(dstLzImpl != address(0));

                txn = abi.encodeWithSelector(
                    LayerzeroV2Implementation.setPeer.selector,
                    lz_chainIds[vars.dstTrueIndex],
                    bytes32(uint256(uint160(dstLzImpl)))
                );
                addToBatch(address(vars.lzImpl), 0, txn);

                address dstWormholeImpl =
                    _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "WormholeARImplementation");
                assert(dstWormholeImpl != address(0));

                txn = abi.encodeWithSelector(
                    WormholeARImplementation.setReceiver.selector, wormhole_chainIds[vars.dstTrueIndex], dstWormholeImpl
                );
                addToBatch(address(vars.wormholeImpl), 0, txn);

                txn = abi.encodeWithSelector(
                    AxelarImplementation.setChainId.selector, vars.dstChainId, axelar_chainIds[vars.dstTrueIndex]
                );
                addToBatch(address(vars.axelarImpl), 0, txn);

                address dstAxelarImpl =
                    _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "AxelarImplementation");
                assert(dstAxelarImpl != address(0));

                txn = abi.encodeWithSelector(
                    AxelarImplementation.setReceiver.selector, axelar_chainIds[vars.dstTrueIndex], dstAxelarImpl
                );
                addToBatch(address(vars.axelarImpl), 0, txn);

                if (vars.dstChainId != 250 && vars.chainId != 250) {
                    assert(vars.dstTrueIndex < hyperlane_chainIds.length);

                    txn = abi.encodeWithSelector(
                        HyperlaneImplementation.setChainId.selector,
                        vars.dstChainId,
                        hyperlane_chainIds[vars.dstTrueIndex]
                    );
                    addToBatch(address(vars.hypImpl), 0, txn);

                    address dstHypImpl =
                        _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "HyperlaneImplementation");
                    assert(dstHypImpl != address(0));

                    txn = abi.encodeWithSelector(
                        HyperlaneImplementation.setReceiver.selector, hyperlane_chainIds[vars.dstTrueIndex], dstHypImpl
                    );
                    addToBatch(address(vars.hypImpl), 0, txn);
                }
            }
        }

        assert(trueIndex < PROTOCOL_ADMINS.length);
        address protocolAdmin = PROTOCOL_ADMINS[trueIndex];
        assert(protocolAdmin != address(0));

        address[] memory rescuerAddress = new address[](TARGET_CHAINS.length);
        bytes32[] memory ids = new bytes32[](TARGET_CHAINS.length);

        for (uint256 i; i < rescuerAddress.length; i++) {
            ids[i] = 0xf98729ec1ce0343ca1d11c51d1d2d3aa1a7b3f4f6876d0611e0a6fa86520a0cb;
            rescuerAddress[i] = 0x90ed07A867bDb6a73565D7abBc7434Dd810Fafc5;
        }

        txn = abi.encodeWithSelector(SuperRegistry.batchSetAddress.selector, ids, rescuerAddress, TARGET_CHAINS);
        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, protocolAdmin, false);
    }

    function _configureDeployedAdaptersStaging(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
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
