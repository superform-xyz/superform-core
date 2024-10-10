/// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";
import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
    SuperformFactory superformFactory;
    SuperRBAC superRBACC;
}

abstract contract AbstractDeployAsyncStateRegistry is EnvironmentUtils {
    function _deployAsyncStateRegistry(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        _preDeploymentSetup();

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

        address newStateRegistry = address(new AsyncStateRegistry{ salt: salt }(ISuperRegistry(superRegistry)));
        contracts[vars.chainId][bytes32(bytes("AsyncStateRegistry"))] = newStateRegistry;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _configureSettingsStaging(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        _preDeploymentSetup();

        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189
            : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        address asyncStateRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AsyncStateRegistry");
        assert(asyncStateRegistry != address(0));

        address[] memory registryAddresses = new address[](2);
        registryAddresses[0] = asyncStateRegistry;

        uint8[] memory registryIds = new uint8[](2);
        registryIds[0] = 4;

        vars.superRegistryC.setStateRegistryAddress(registryIds, registryAddresses);

        vars.superRegistryC.setAddress(
            keccak256("ASYNC_STATE_REGISTRY_PROCESSOR"), ASYNC_STATE_REGISTRY_PROCESSOR, vars.chainId
        );

        vars.superRBACC = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));

        vars.superRBACC.setRoleAdmin(
            keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE"), vars.superRBACC.PROTOCOL_ADMIN_ROLE()
        );
        vars.superRBACC.grantRole(keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE"), ASYNC_STATE_REGISTRY_PROCESSOR);

        vm.stopBroadcast();
    }

    function _configureSettingsProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        _preDeploymentSetup();

        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[i];

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        assert(address(vars.superRegistryC) == expectedSr);

        address asyncStateRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "AsyncStateRegistry");
        assert(asyncStateRegistry != address(0));

        address[] memory registryAddresses = new address[](1);
        registryAddresses[0] = asyncStateRegistry;

        uint8[] memory registryIds = new uint8[](1);
        registryIds[0] = 4;

        bytes memory txn =
            abi.encodeWithSelector(vars.superRegistryC.setStateRegistryAddress.selector, registryIds, registryAddresses);
        addToBatch(address(vars.superRegistryC), 0, txn);

        txn = abi.encodeWithSelector(
            SuperRegistry.setAddress.selector,
            keccak256("ASYNC_STATE_REGISTRY_PROCESSOR"),
            ASYNC_STATE_REGISTRY_PROCESSOR,
            vars.chainId
        );
        addToBatch(address(vars.superRegistryC), 0, txn);
        vars.superRBACC = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));

        txn = abi.encodeWithSelector(
            vars.superRBACC.setRoleAdmin.selector,
            keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE"),
            vars.superRBACC.PROTOCOL_ADMIN_ROLE()
        );
        addToBatch(address(vars.superRBACC), 0, txn);

        txn = abi.encodeWithSelector(
            vars.superRBACC.grantRole.selector,
            keccak256("ASYNC_STATE_REGISTRY_PROCESSOR_ROLE"),
            ASYNC_STATE_REGISTRY_PROCESSOR
        );
        addToBatch(address(vars.superRBACC), 0, txn);

        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], 0, false);
    }
}
