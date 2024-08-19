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

/// @dev deploys Axelar Bridge
/// @dev on staging sets the new AMBs in super registry
abstract contract AbstractDeployAxelar is EnvironmentUtils {
    function _deployAxelar(
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

        vars.axelarImplementation = address(new AxelarImplementation{ salt: salt }(ISuperRegistry(superRegistry)));
        contracts[vars.chainId][bytes32(bytes("AxelarImplementation"))] = vars.axelarImplementation;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addAxelarSuperRegistryStaging(
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
            uint8[] memory bridgeIds = new uint8[](1);

            /// axelar
            bridgeIds[0] = 10;

            address[] memory bridgeAddress = new address[](1);
            bridgeAddress[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation");

            assert(bridgeAddress[0] != address(0));

            vars.superRegistryC =
                SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
            address expectedSr = 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
            assert(address(vars.superRegistryC) == expectedSr);

            vars.superRegistryC.setAmbAddress(bridgeIds, bridgeAddress, new bool[](1));
        } else {
            uint8[] memory bridgeIds = new uint8[](1);

            /// axelar
            bridgeIds[0] = 10;

            address[] memory bridgeAddress = new address[](1);
            bridgeAddress[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation");

            assert(bridgeAddress[0] != address(0));

            vars.superRegistryC =
                SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
            address expectedSr = 0x7B8d68f90dAaC67C577936d3Ce451801864EF189;
            assert(address(vars.superRegistryC) == expectedSr);

            vars.superRegistryC.setAmbAddress(bridgeIds, bridgeAddress, new bool[](1));
        }
        vm.stopBroadcast();
    }

    function _configureAxelar(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        if (env == 0) _configureAxelarProd(env, i, trueIndex, cycle, s_superFormChainIds);
        if (env == 1) _configureAxelarStaging(env, i, trueIndex, cycle, s_superFormChainIds);
    }

    function _configureAxelarStaging(
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

        AxelarImplementation axelarImpl =
            AxelarImplementation(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation"));

        axelarImpl.setAxelarConfig(IAxelarGateway(axelarGateway[trueIndex]));
        axelarImpl.setAxelarGasService(
            IAxelarGasService(axelarGasService[trueIndex]), IInterchainGasEstimation(axelarGasService[trueIndex])
        );

        for (uint256 j; j < TARGET_CHAINS.length; j++) {
            vars.dstChainId = TARGET_CHAINS[j];
            if (vars.chainId != vars.dstChainId) {
                vars.dstTrueIndex = _getTrueIndex(vars.dstChainId);

                /// set chain ids
                axelarImpl.setChainId(vars.dstChainId, axelar_chainIds[vars.dstTrueIndex]);

                /// set receivers
                axelarImpl.setReceiver(
                    axelar_chainIds[vars.dstTrueIndex],
                    _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "AxelarImplementation")
                );
            }
        }

        vm.stopBroadcast();
    }

    function _configureAxelarProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle, /*cycle*/
        uint64[] memory s_superFormChainIds
    )
        internal
    {
        assert(salt.length > 0);
        UpdateVars memory vars;
        vars.chainId = s_superFormChainIds[i];

        AxelarImplementation axelarImpl =
            AxelarImplementation(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "AxelarImplementation"));

        bytes memory txn = abi.encodeWithSelector(
            AxelarImplementation.setAxelarConfig.selector, IAxelarGateway(axelarGateway[trueIndex])
        );
        addToBatch(address(axelarImpl), 0, txn);

        txn = abi.encodeWithSelector(
            AxelarImplementation.setAxelarGasService.selector,
            IAxelarGasService(axelarGasService[trueIndex]),
            IInterchainGasEstimation(axelarGasService[trueIndex])
        );
        addToBatch(address(axelarImpl), 0, txn);

        for (uint256 j; j < TARGET_CHAINS.length; j++) {
            vars.dstChainId = TARGET_CHAINS[j];
            if (vars.chainId != vars.dstChainId) {
                vars.dstTrueIndex = _getTrueIndex(vars.dstChainId);

                txn = abi.encodeWithSelector(
                    AxelarImplementation.setChainId.selector, vars.dstChainId, axelar_chainIds[vars.dstTrueIndex]
                );
                addToBatch(address(axelarImpl), 0, txn);

                txn = abi.encodeWithSelector(
                    AxelarImplementation.setReceiver.selector,
                    axelar_chainIds[vars.dstTrueIndex],
                    _readContractsV1(env, chainNames[vars.dstTrueIndex], vars.dstChainId, "AxelarImplementation")
                );
                addToBatch(address(axelarImpl), 0, txn);
            }
        }

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], false);
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
