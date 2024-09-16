/// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import "src/interfaces/ISuperRegistry.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
    SuperformFactory superformFactory;
    AxelarImplementation axelarImpl;
    LayerzeroImplementation lzV1Impl;
    LayerzeroImplementation layerzeroImpl;
    HyperlaneImplementation hyperlaneImpl;
    WormholeARImplementation wormholeImpl;
}

abstract contract AbstractConfigure5115FormAndDisableAMB is EnvironmentUtils {
    function _deployLayerzeroV1(
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

        contracts[vars.chainId][bytes32(bytes("LayerzeroV1Implementation"))] =
            address(new LayerzeroImplementation{ salt: salt }(ISuperRegistry(superRegistry)));

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _deployPaymentHelperV2(
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

        contracts[vars.chainId][bytes32(bytes("PaymentHelper"))] =
            address(new PaymentHelper{ salt: salt }(ISuperRegistry(superRegistry)));

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _configureERC5115AndDisableOldAMBs(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        if (env == 0) _configureProd(env, i, trueIndex, cycle, finalDeployedChains);
        else _configureStaging(env, i, trueIndex, cycle, finalDeployedChains);
    }

    function _configureProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

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

        address erc5115Form = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "ERC5115Form");
        assert(erc5115Form != address(0));

        /// @notice can ERC5115 be at id:3 on prod
        bytes memory txn = abi.encodeWithSelector(SuperformFactory.addFormImplementation.selector, erc5115Form, 3, 1);
        addToBatch(superRegistry, 0, txn);

        /// @notice new layerzero v1 implementation is at id:9 on prod
        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 9;

        address[] memory ambAddress = new address[](1);
        ambAddress[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroV1Implementation");
        assert(ambAddress[0] != address(0));

        txn = abi.encodeWithSelector(SuperRegistry.setAmbAddress.selector, ambIds, ambAddress, new bool[](1));
        addToBatch(superRegistry, 0, txn);

        vars.axelarImpl =
            AxelarImplementation(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation"));

        vars.lzV1Impl = LayerzeroImplementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroV1Implementation")
        );

        assert(address(vars.axelarImpl) != address(0));
        assert(address(vars.lzV1Impl) != address(0));

        /// @dev adding the old implementations as variables here
        vars.hyperlaneImpl = HyperlaneImplementation(0x207BFE0Fb040F17cC61B67e4aaDfC59C9e170671);
        vars.layerzeroImpl = vars.chainId == 250
            ? LayerzeroImplementation(0x9061774Bd32D9C4552c540a822823949Fad006D9)
            : LayerzeroImplementation(0x1863862794cD8ec60daBF8B473fcA928B78cE563);
        vars.wormholeImpl = vars.chainId == 250
            ? WormholeARImplementation(0x0545Ecc81aC5855b1D55578B03431d986eDEA746)
            : WormholeARImplementation(0x3b6FABE94a5d0B160e2E1519495e7Fe9dD009Ea3);

        txn = abi.encodeWithSelector(LayerzeroImplementation.setLzEndpoint.selector, lzEndpoints[trueIndex]);
        addToBatch(address(vars.lzV1Impl), 0, txn);

        for (uint256 j; j < TARGET_CHAINS.length; j++) {
            vars.dstChainId = TARGET_CHAINS[j];
            if (vars.chainId != vars.dstChainId) {
                vars.dstTrueIndex = _getTrueIndex(vars.dstChainId);

                /// @dev configure new Lz v1
                txn = abi.encodeWithSelector(
                    LayerzeroImplementation.setChainId.selector, vars.dstChainId, lz_v1_chainIds[vars.dstTrueIndex]
                );
                addToBatch(address(vars.lzV1Impl), 0, txn);

                txn = abi.encodeWithSelector(
                    LayerzeroImplementation.setTrustedRemote.selector,
                    lz_v1_chainIds[vars.dstTrueIndex],
                    abi.encodePacked(
                        _readContractsV1(
                            env, chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroV1Implementation"
                        ),
                        address(vars.lzV1Impl)
                    )
                );
                addToBatch(address(vars.lzV1Impl), 0, txn);

                /// @dev set receivers to 0xDEAD
                txn = abi.encodeWithSelector(
                    AxelarImplementation.setReceiver.selector, axelar_chainIds[vars.dstTrueIndex], address(0xDEAD)
                );
                addToBatch(address(vars.axelarImpl), 0, txn);

                /// @dev old layerzero, hyperlane and wormhole are only deployed on the previous networks
                if (
                    vars.chainId == LINEA || vars.chainId == BLAST || vars.dstChainId == BLAST
                        || vars.dstChainId == LINEA
                ) continue;
                txn = abi.encodeWithSelector(
                    LayerzeroImplementation.setTrustedRemote.selector,
                    lz_v1_chainIds[vars.dstTrueIndex],
                    abi.encodePacked(address(0xDEAD), address(0xDEAD))
                );
                addToBatch(address(vars.layerzeroImpl), 0, txn);

                txn = abi.encodeWithSelector(
                    WormholeARImplementation.setReceiver.selector, wormhole_chainIds[vars.dstTrueIndex], address(0xDEAD)
                );
                addToBatch(address(vars.wormholeImpl), 0, txn);

                if (vars.chainId == FANTOM || vars.dstChainId == FANTOM) continue;
                txn = abi.encodeWithSelector(
                    HyperlaneImplementation.setReceiver.selector, hyperlane_chainIds[vars.dstTrueIndex], address(0xDEAD)
                );
                addToBatch(address(vars.hyperlaneImpl), 0, txn);
            }
        }

        /// Send to Safe to sign
        executeBatch(vars.chainId, PROTOCOL_ADMINS[trueIndex], 0, false);
    }

    function _configureStaging(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

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

        uint8[] memory ambIds = new uint8[](1);
        ambIds[0] = 21;

        address[] memory ambAddress = new address[](1);
        ambAddress[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroV1Implementation");

        bool[] memory isBroadcastAMB = new bool[](1);
        isBroadcastAMB[0] = false;
        assert(ambAddress[0] != address(0));

        /// @dev add the new layerzero v1 implementation to id 15 on staging
        SuperRegistry(superRegistry).setAmbAddress(ambIds, ambAddress, isBroadcastAMB);

        vars.axelarImpl =
            AxelarImplementation(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation"));
        vars.lzV1Impl = LayerzeroImplementation(
            _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LayerzeroV1Implementation")
        );
        assert(address(vars.axelarImpl) != address(0));
        assert(address(vars.lzV1Impl) != address(0));

        /// @dev adding the old implementations as variables here
        vars.hyperlaneImpl = HyperlaneImplementation(0x207BFE0Fb040F17cC61B67e4aaDfC59C9e170671);
        vars.layerzeroImpl = vars.chainId == 250
            ? LayerzeroImplementation(0x9061774Bd32D9C4552c540a822823949Fad006D9)
            : LayerzeroImplementation(0x1863862794cD8ec60daBF8B473fcA928B78cE563);
        vars.wormholeImpl = vars.chainId == 250
            ? WormholeARImplementation(0x0545Ecc81aC5855b1D55578B03431d986eDEA746)
            : WormholeARImplementation(0x3b6FABE94a5d0B160e2E1519495e7Fe9dD009Ea3);

        vars.lzV1Impl.setLzEndpoint(lzEndpoints[trueIndex]);

        for (uint256 j; j < TARGET_CHAINS.length; j++) {
            vars.dstChainId = TARGET_CHAINS[j];
            if (vars.chainId != vars.dstChainId) {
                vars.dstTrueIndex = _getTrueIndex(vars.dstChainId);

                /// @dev set receivers to 0xDEAD
                vars.axelarImpl.setReceiver(axelar_chainIds[vars.dstTrueIndex], address(0xDEAD));

                /// @dev configure new Lz v1
                vars.lzV1Impl.setChainId(vars.dstChainId, lz_v1_chainIds[vars.dstTrueIndex]);
                vars.lzV1Impl.setTrustedRemote(
                    lz_v1_chainIds[vars.dstTrueIndex],
                    abi.encodePacked(
                        _readContractsV1(
                            env, chainNames[vars.dstTrueIndex], vars.dstChainId, "LayerzeroV1Implementation"
                        ),
                        address(vars.lzV1Impl)
                    )
                );

                /// @dev old layerzero, hyperlane and wormhole are only deployed on the previous networks
                if (
                    vars.chainId == LINEA || vars.chainId == BLAST || vars.dstChainId == BLAST
                        || vars.dstChainId == LINEA
                ) continue;
                vars.layerzeroImpl.setTrustedRemote(
                    lz_v1_chainIds[vars.dstTrueIndex], abi.encodePacked(address(0xDEAD), address(0xDEAD))
                );
                vars.wormholeImpl.setReceiver(wormhole_chainIds[vars.dstTrueIndex], address(0xDEAD));

                if (vars.chainId == FANTOM || vars.dstChainId == FANTOM) continue;
                vars.hyperlaneImpl.setReceiver(hyperlane_chainIds[vars.dstTrueIndex], address(0xDEAD));
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
