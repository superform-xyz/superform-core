// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeployDeBridgeValidators is EnvironmentUtils {
    mapping(uint64 chainId => address[] bridgeAddresses) public NEW_BRIDGE_ADDRESSES;

    function _deployDebridge(
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

        vars.deBridgeValidator = address(new DeBridgeValidator{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("DeBridgeValidator"))] = vars.deBridgeValidator;

        vars.deBridgeForwarderValidator = address(new DeBridgeForwarderValidator{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("DeBridgeForwarderValidator"))] = vars.deBridgeForwarderValidator;

        vm.stopBroadcast();

        /// @dev we use normal export contract to not override v1 contracts
        for (uint256 j; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addDeBridgeValidatorsToSuperRegistryStaging(
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

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[BSC] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[AVAX] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[POLY] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[ARBI] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[OP] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[BASE] = [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];
        bridgeAddresses[FANTOM] =
            [0xeF4fB24aD0916217251F553c0596F8Edc630EB66, 0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251];

        address[] memory bridgeValidators = new address[](2);
        uint8[] memory newBridgeids = new uint8[](2);

        bridgeValidators[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "DeBridgeValidator");
        newBridgeids[0] = 12;

        bridgeValidators[1] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "DeBridgeForwarderValidator");
        newBridgeids[1] = 13;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));
        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][1] != address(0));
        assert(bridgeValidators[0] != address(0));
        assert(bridgeValidators[1] != address(0));

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
