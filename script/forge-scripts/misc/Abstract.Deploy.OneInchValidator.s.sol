// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeployOneInchValidator is EnvironmentUtils {
    mapping(uint64 chainId => address[] bridgeAddresses) public NEW_BRIDGE_ADDRESSES;

    function _deployOneInch(
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

        vars.oneInchValidator = address(new OneInchValidator{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("OneInchValidator"))] = vars.oneInchValidator;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addOneInchValidatorToSuperRegistry(
        uint256 env,
        uint256 i,
        uint256 trueIndex,
        Cycle cycle,
        uint64[] memory s_superFormChainIds
    )
        internal
        setEnvDeploy(cycle)
    {
        if (env == 0) _addOneInchValidatorToSuperRegistryProd(env, i, trueIndex, cycle, s_superFormChainIds);
        else if (env == 1) _addOneInchValidatorToSuperRegistryStaging(env, i, trueIndex, cycle, s_superFormChainIds);
    }

    function _addOneInchValidatorToSuperRegistryProd(
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

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[BSC] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[AVAX] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[POLY] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[ARBI] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[OP] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[BASE] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[FANTOM] = [0x111111125421cA6dc452d289314280a0f8842A65];

        address[] memory bridgeValidators = new address[](1);
        uint8[] memory newBridgeids = new uint8[](1);

        bridgeValidators[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "OneInchValidator");
        newBridgeids[0] = 4;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));
        assert(bridgeValidators[0] != address(0));

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));

        address expectedSr = vars.chainId == 250
            ? 0x7feB31d18E43E2faeC718EEd2D7f34402c3e27b4
            : 0x17A332dC7B40aE701485023b219E9D6f493a2514;

        assert(address(vars.superRegistryC) == expectedSr);

        bytes memory txn = abi.encodeWithSelector(
            SuperRegistry.setBridgeAddresses.selector,
            newBridgeids,
            NEW_BRIDGE_ADDRESSES[vars.chainId],
            bridgeValidators
        );

        addToBatch(address(vars.superRegistryC), 0, txn);
        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], true);
    }

    function _addOneInchValidatorToSuperRegistryStaging(
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

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[BSC] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[AVAX] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[POLY] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[ARBI] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[OP] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[BASE] = [0x111111125421cA6dc452d289314280a0f8842A65];
        bridgeAddresses[FANTOM] = [0x111111125421cA6dc452d289314280a0f8842A65];

        address[] memory bridgeValidators = new address[](1);
        uint8[] memory newBridgeids = new uint8[](1);

        bridgeValidators[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "OneInchValidator");
        newBridgeids[0] = 9;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));
        assert(bridgeValidators[0] != address(0));

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr = vars.chainId == 250
            ? 0x7B8d68f90dAaC67C577936d3Ce451801864EF189
            : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        vars.superRegistryC.setBridgeAddresses(newBridgeids, NEW_BRIDGE_ADDRESSES[vars.chainId], bridgeValidators);

        vm.stopBroadcast();
    }
}
