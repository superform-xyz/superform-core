/// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    SuperRegistry superRegistryC;
}

abstract contract FixPostPreBeraStuff is EnvironmentUtils {
    function _configure(
        uint256 env,
        uint256 srcChainIndex,
        Cycle cycle,
        uint64[] memory finalDeployedChains
    )
        internal
        setEnvDeploy(cycle)
    {
        assert(salt.length > 0);
        UpdateVars memory vars;

        vars.chainId = finalDeployedChains[srcChainIndex];

        vars.superRegistryC =
            SuperRegistry(_readContractsV1(env, chainNames[srcChainIndex], vars.chainId, "SuperRegistry"));
        assert(address(vars.superRegistryC) != address(0));

        bytes memory txn;

        address[] memory rescuerAddress = new address[](2);
        bytes32[] memory ids = new bytes32[](2);
        uint64[] memory targetChains = new uint64[](2);
        targetChains[0] = LINEA;
        targetChains[1] = BLAST;

        for (uint256 j; j < finalDeployedChains.length; j++) {
            if (finalDeployedChains[j] == vars.chainId) {
                continue;
            }

            // disable Axelar's other chain info on LINEA and BLAST
            if (vars.chainId == LINEA || vars.chainId == BLAST) { } else {
                for (uint256 i; i < rescuerAddress.length; i++) {
                    ids[i] = keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE");
                    rescuerAddress[i] = CSR_RESCUER;
                }
                txn = abi.encodeWithSelector(
                    vars.superRegistryC.batchSetAddress.selector, ids, rescuerAddress, targetChains
                );
                addToBatch(address(vars.superRegistryC), 0, txn);
            }
        }

        // Send the batch
        executeBatch(vars.chainId, PROTOCOL_ADMINS[srcChainIndex], manualNonces[srcChainIndex], true);
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
