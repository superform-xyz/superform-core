// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address broadcastRegistry;
    address superRegistry;
    address superRBAC;
    bytes32[] ids;
    address[] newAddresses;
    uint64[] chainIdsSetAddresses;
    SuperRegistry superRegistryC;
    SuperRBAC superRBACC;
}

abstract contract AbstractEnableBroadcasting is EnvironmentUtils {
    function _enableBroadcasting(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        UpdateVars memory vars;

        vars.chainId = targetDeploymentChains[i];
        vm.startBroadcast();
        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.superRegistryC = SuperRegistry(vars.superRegistry);
        vars.superRBAC = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC");
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        vars.broadcastRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "BroadcastRegistry");

        if (vars.superRegistry == address(0) || vars.broadcastRegistry == address(0) || vars.superRBAC == address(0)) {
            revert();
        }
        /// set addresses in super rbac
        vars.superRBACC.grantRole(
            vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), BROADCAST_REGISTRY_PROCESSOR
        );

        vars.superRBACC.grantRole(vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), WORMHOLE_VAA_RELAYER);

        /// set addresses in super registry
        vars.ids = new bytes32[](2);
        vars.newAddresses = new address[](2);
        vars.chainIdsSetAddresses = new uint64[](2);

        vars.ids[0] = vars.superRegistryC.BROADCAST_REGISTRY();
        vars.ids[1] = vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR();

        vars.newAddresses[0] = vars.broadcastRegistry;
        vars.newAddresses[1] = BROADCAST_REGISTRY_PROCESSOR;

        vars.chainIdsSetAddresses[0] = vars.chainId;
        vars.chainIdsSetAddresses[1] = vars.chainId;

        vars.superRegistryC.batchSetAddress(vars.ids, vars.newAddresses, vars.chainIdsSetAddresses);

        for (uint256 j = 0; j < targetDeploymentChains.length; j++) {
            if (j != i) {
                vars.dstChainId = targetDeploymentChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }

                vars.superRegistryC.setAddress(
                    vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR(), BROADCAST_REGISTRY_PROCESSOR, vars.dstChainId
                );
            }
        }
        vm.stopBroadcast();
    }

    function _enableBroadcastingProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(env == 0);
        UpdateVars memory vars;

        vars.chainId = targetDeploymentChains[i];
        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.superRegistryC = SuperRegistry(vars.superRegistry);
        vars.superRBAC = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC");
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        vars.broadcastRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "BroadcastRegistry");

        if (vars.superRegistry == address(0) || vars.broadcastRegistry == address(0) || vars.superRBAC == address(0)) {
            revert();
        }
        bytes memory txn = abi.encodeWithSelector(
            vars.superRBACC.grantRole.selector,
            vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(),
            BROADCAST_REGISTRY_PROCESSOR
        );
        addToBatch(address(vars.superRBACC), 0, txn);
        txn = abi.encodeWithSelector(
            vars.superRBACC.grantRole.selector, vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), WORMHOLE_VAA_RELAYER
        );
        addToBatch(address(vars.superRBACC), 0, txn);

        /// set addresses in super registry
        vars.ids = new bytes32[](2);
        vars.newAddresses = new address[](2);
        vars.chainIdsSetAddresses = new uint64[](2);

        vars.ids[0] = vars.superRegistryC.BROADCAST_REGISTRY();
        vars.ids[1] = vars.superRegistryC.BROADCAST_REGISTRY_PROCESSOR();

        vars.newAddresses[0] = vars.broadcastRegistry;
        vars.newAddresses[1] = BROADCAST_REGISTRY_PROCESSOR;

        vars.chainIdsSetAddresses[0] = vars.chainId;
        vars.chainIdsSetAddresses[1] = vars.chainId;

        txn = abi.encodeWithSelector(
            vars.superRegistryC.batchSetAddress.selector, vars.ids, vars.newAddresses, vars.chainIdsSetAddresses
        );

        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], 0, true);
    }

    function _revokeRole(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        UpdateVars memory vars;

        vars.chainId = targetDeploymentChains[i];
        vm.startBroadcast();
        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.superRegistryC = SuperRegistry(vars.superRegistry);
        vars.superRBAC = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC");
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        vars.broadcastRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "BroadcastRegistry");

        if (vars.superRegistry == address(0) || vars.broadcastRegistry == address(0) || vars.superRBAC == address(0)) {
            revert();
        }
        /// revoke addresses in super rbac
        vars.superRBACC.revokeRole(vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(), EMERGENCY_ADMIN);

        vars.superRBACC.revokeRole(vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), EMERGENCY_ADMIN);

        vm.stopBroadcast();
    }

    function _revokeRoleProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory targetDeploymentChains
    )
        internal
        setEnvDeploy(cycle)
    {
        UpdateVars memory vars;

        vars.chainId = targetDeploymentChains[i];
        vars.superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        vars.superRegistryC = SuperRegistry(vars.superRegistry);
        vars.superRBAC = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC");
        vars.superRBACC = SuperRBAC(vars.superRBAC);

        vars.broadcastRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "BroadcastRegistry");

        if (vars.superRegistry == address(0) || vars.broadcastRegistry == address(0) || vars.superRBAC == address(0)) {
            revert();
        }

        bytes memory txn = abi.encodeWithSelector(
            vars.superRBACC.revokeRole.selector,
            vars.superRBACC.BROADCAST_STATE_REGISTRY_PROCESSOR_ROLE(),
            EMERGENCY_ADMIN
        );

        addToBatch(address(vars.superRBACC), 0, txn);

        txn = abi.encodeWithSelector(
            vars.superRBACC.revokeRole.selector, vars.superRBACC.WORMHOLE_VAA_RELAYER_ROLE(), EMERGENCY_ADMIN
        );

        addToBatch(address(vars.superRBACC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], 0, true);
    }
}
