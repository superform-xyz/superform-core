// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
    SuperRBAC superRBACC;
}

abstract contract AbstractDeployRewardsDistributor is EnvironmentUtils {
    function _deployRewardsDistributor(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
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

        address rewards = address(new RewardsDistributor{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("RewardsDistributor"))] = rewards;

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

        address rewards = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "RewardsDistributor");

        bytes32 rewardsId = keccak256("REWARDS_DISTRIBUTOR");

        vars.superRegistryC.setAddress(rewardsId, rewards, vars.chainId);

        vars.superRBACC = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));

        /// @dev configure remotes based on source chain
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }

                vars.superRegistryC.setAddress(rewardsId, rewards, vars.dstChainId);
            }
        }

        /// @dev rewards admin has already been set on staging

        address expectedSrbac = vars.chainId == 250
            ? 0xFFe9AFe35806F3fc1Df81188953ADb72f0B22F2A
            : 0x9736b60c4f749232d400B5605f21AE137a5Ebb71;

        assert(address(vars.superRBACC) == expectedSrbac);

        bytes32 role = keccak256("REWARDS_ADMIN_ROLE");
        assert(REWARDS_ADMIN != address(0));

        vars.superRBACC.setRoleAdmin(role, vars.superRBACC.PROTOCOL_ADMIN_ROLE());
        vars.superRBACC.grantRole(role, REWARDS_ADMIN);

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

        address rewards = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "RewardsDistributor");
        bytes32 rewardsId = keccak256("REWARDS_DISTRIBUTOR");

        bytes memory txn =
            abi.encodeWithSelector(vars.superRegistryC.setAddress.selector, rewardsId, rewards, vars.chainId);
        addToBatch(address(vars.superRegistryC), 0, txn);

        vars.superRBACC = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));

        address expectedSrbac = vars.chainId == 250
            ? 0xd831b4ba49852F6E7246Fe7f4A7DABB5b0C56e1F
            : 0x480bec236e3d3AE33789908BF024850B2Fe71258;

        assert(address(vars.superRBACC) == expectedSrbac);

        bytes32 role = keccak256("REWARDS_ADMIN_ROLE");
        assert(REWARDS_ADMIN != address(0));

        txn = abi.encodeWithSelector(vars.superRBACC.setRoleAdmin.selector, role, vars.superRBACC.PROTOCOL_ADMIN_ROLE());

        addToBatch(address(vars.superRBACC), 0, txn);

        txn = abi.encodeWithSelector(vars.superRBACC.grantRole.selector, role, REWARDS_ADMIN);

        addToBatch(address(vars.superRBACC), 0, txn);

        /// @dev configure remotes based on source chain
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }

                txn =
                    abi.encodeWithSelector(vars.superRegistryC.setAddress.selector, rewardsId, rewards, vars.dstChainId);

                addToBatch(address(vars.superRegistryC), 0, txn);
            }
        }
        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], 0, false);
    }
}
