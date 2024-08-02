// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeployPayloadHelper is EnvironmentUtils {
    function _deployPayloadHelper(
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

        address payloadHelper = address(new PayloadHelper{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("PayloadHelper"))] = payloadHelper;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addPayloadHelperToSuperRegistry(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        if (env == 0) _addPayloadHelperToSuperRegistryProd(env, i, trueIndex, cycle, s_superFormChainIds);
        else if (env == 1) _addPayloadHelperToSuperRegistryStaging(env, i, trueIndex, cycle, s_superFormChainIds);
    }

    function _addPayloadHelperToSuperRegistryProd(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle, /*cycle*/
        uint64[] memory s_superFormChainIds
    )
        internal
    {
        assert(salt.length > 0);
        assert(env == 0);
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        address payloadHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PayloadHelper");

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;
        assert(address(vars.superRegistryC) == expectedSr);

        bytes memory txn = abi.encodeWithSelector(
            SuperRegistry.setAddress.selector, vars.superRegistryC.PAYLOAD_HELPER(), payloadHelper, vars.chainId
        );

        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], false);
    }

    function _addPayloadHelperToSuperRegistryStaging(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
    {
        assert(salt.length > 0);
        assert(env == 1);
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];
        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        address payloadHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PayloadHelper");

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189
            : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        vars.superRegistryC.setAddress(vars.superRegistryC.PAYLOAD_HELPER(), payloadHelper, vars.chainId);

        vm.stopBroadcast();
    }
}
