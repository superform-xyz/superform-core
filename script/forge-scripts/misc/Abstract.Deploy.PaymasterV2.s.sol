// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

import { BatchScript } from "../safe/BatchScript.sol";


struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address paymaster;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeployPaymasterV2 is BatchScript, EnvironmentUtils {
    function _deployPaymasterV2(
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
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        vars.paymaster = address(new PayMaster{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("PayMaster"))] = vars.paymaster;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addPaymasterV2ToSuperRegistryStaging(
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

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);
        vars.paymaster = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PayMaster");

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYMASTER(), vars.paymaster, vars.chainId);

        /// @dev Set all trusted remotes for each chain & configure amb chains ids
        for (uint256 j = 0; j < finalDeployedChains.length; j++) {
            if (j != i) {
                vars.dstChainId = finalDeployedChains[j];

                for (uint256 k = 0; k < chainIds.length; k++) {
                    if (vars.dstChainId == chainIds[k]) {
                        vars.dstTrueIndex = k;

                        break;
                    }
                }

                vars.superRegistryC.setAddress(vars.superRegistryC.PAYMASTER(), vars.paymaster, vars.dstChainId);
            }
        }

        vm.stopBroadcast();
    }
}
