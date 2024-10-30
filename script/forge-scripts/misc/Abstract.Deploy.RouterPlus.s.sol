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

abstract contract AbstractDeployRouterPlus is EnvironmentUtils {
    function _deployRouterPlusStaging(
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

        address superformRouterPlus = address(new SuperformRouterPlus{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("SuperformRouterPlus"))] = superformRouterPlus;

        SuperRegistry(superRegistry).setAddress(keccak256("SUPERFORM_ROUTER_PLUS"), superformRouterPlus, vars.chainId);

        address superformRouterPlusAsync = address(new SuperformRouterPlusAsync{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("SuperformRouterPlusAsync"))] = superformRouterPlusAsync;

        SuperRegistry(superRegistry).setAddress(
            keccak256("SUPERFORM_ROUTER_PLUS_ASYNC"), superformRouterPlusAsync, vars.chainId
        );

        /// @dev below part is already done
        /*
        SuperRegistry(superRegistry).setAddress(
            keccak256("ROUTER_PLUS_PROCESSOR_ROLE"), ROUTER_PLUS_PROCESSOR, vars.chainId
        );

        vars.superRBACC = SuperRBAC(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRBAC")));

        vars.superRBACC.setRoleAdmin(keccak256("ROUTER_PLUS_PROCESSOR_ROLE"), vars.superRBACC.PROTOCOL_ADMIN_ROLE());
        vars.superRBACC.grantRole(keccak256("ROUTER_PLUS_PROCESSOR_ROLE"), ROUTER_PLUS_PROCESSOR);
        */

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }
}
