// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    address paymaster;
    SuperRegistry superRegistryC;
}

abstract contract AbstractSuperRegistryLiFiValidatorV2 is EnvironmentUtils {
    mapping(uint64 chainId => address[] bridgeAddresses) public NEW_BRIDGE_ADDRESSES;

    function _addPaymasterLiFiValidatorV2ToSuperRegistryProd(
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

        vars.superRegistryC =
            SuperRegistry(payable(_readContractsV1(env, chainNames[trueIndex], vars.chainId, "SuperRegistry")));
        address expectedSr =
            env == 0 ? 0x17A332dC7B40aE701485023b219E9D6f493a2514 : 0xB2C097ac459aFAc892ae5b35f6bd6a9Dd3071F47;
        assert(address(vars.superRegistryC) == expectedSr);

        /// @dev PaymasterV2 logic into SuperRegistry

        vars.paymaster = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PayMaster");

        bytes memory txn = abi.encodeWithSelector(
            vars.superRegistryC.setAddress.selector, vars.superRegistryC.PAYMASTER(), vars.paymaster, vars.chainId
        );
        addToBatch(address(vars.superRegistryC), 0, txn);

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
                txn = abi.encodeWithSelector(
                    vars.superRegistryC.setAddress.selector,
                    vars.superRegistryC.PAYMASTER(),
                    vars.paymaster,
                    vars.dstChainId
                );

                addToBatch(address(vars.superRegistryC), 0, txn);
            }
        }

        /// @dev LiFiValidatorV2 logic into SuperRegistry

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
        newBridgeids[0] = 101;

        assert(NEW_BRIDGE_ADDRESSES[vars.chainId][0] != address(0));

        txn = abi.encodeWithSelector(
            SuperRegistry.setBridgeAddresses.selector,
            newBridgeids,
            NEW_BRIDGE_ADDRESSES[vars.chainId],
            bridgeValidators
        );

        addToBatch(address(vars.superRegistryC), 0, txn);

        /// Send to Safe to sign
        executeBatch(vars.chainId, env == 0 ? PROTOCOL_ADMINS[trueIndex] : PROTOCOL_ADMINS_STAGING[i], true);
    }
}
