// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

import { BatchScript } from "../safe/BatchScript.sol";

import "forge-std/console.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address lifiValidatorV2;
    SuperRegistry superRegistryC;
}

abstract contract AbstractDeployLiFiValidatorV2 is BatchScript, EnvironmentUtils {
    mapping(uint64 chainId => address[] bridgeAddresses) public NEW_BRIDGE_ADDRESSES;

    function _deployLiFiValidatorV2(
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
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        address superRegistry = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry");
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(superRegistry == expectedSr);

        vars.lifiValidatorV2 = address(new LiFiValidator{ salt: salt }(superRegistry));
        contracts[vars.chainId][bytes32(bytes("LiFiValidator"))] = vars.lifiValidatorV2;

        vm.stopBroadcast();

        for (uint256 j = 0; j < contractNames.length; j++) {
            _exportContract(
                chainNames[trueIndex], contractNames[j], getContract(vars.chainId, contractNames[j]), vars.chainId
            );
        }
    }

    function _addLiFiValidatorV2ToSuperRegistryStaging(
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
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];
        cycle == Cycle.Dev ? vm.startBroadcast(deployerPrivateKey) : vm.startBroadcast();

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[BSC] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[AVAX] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[POLY] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[ARBI] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[OP] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[BASE] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];

        address[] memory bridgeValidators = new address[](1);
        uint8[] memory newBridgeids = new uint8[](1);

        bridgeValidators[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LiFiValidator");
        newBridgeids[0] = 4;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        vars.superRegistryC.setBridgeAddresses(newBridgeids, NEW_BRIDGE_ADDRESSES[vars.chainId], bridgeValidators);

        vm.stopBroadcast();
    }

    /// requires protocol admin
    function _addLiFiValidatorV2ToSuperRegistryProd(
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
        UpdateVars memory vars;

        vars.chainId = s_superFormChainIds[i];

        mapping(uint64 chainId => address[] bridgeAddresses) storage bridgeAddresses = NEW_BRIDGE_ADDRESSES;

        bridgeAddresses[ETH] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[BSC] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[AVAX] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[POLY] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[ARBI] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[OP] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];
        bridgeAddresses[BASE] = [0x1231DEB6f5749EF6cE6943a275A1D3E7486F4EaE];

        address[] memory bridgeValidators = new address[](1);
        uint8[] memory newBridgeids = new uint8[](1);

        bridgeValidators[0] = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "LiFiValidator");
        newBridgeids[0] = 4;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);
        bytes memory txn = abi.encodeWithSelector(
            SuperRegistry.setBridgeAddresses.selector,
            newBridgeids,
            NEW_BRIDGE_ADDRESSES[vars.chainId],
            bridgeValidators
        );

        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], false);
    }
}
