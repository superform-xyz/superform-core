// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import "../EnvironmentUtils.s.sol";

struct UpdateVars {
    uint64 chainId;
    uint64 dstChainId;
    uint256 dstTrueIndex;
    SuperRegistry superRegistryC;
}

abstract contract AbstractTest is EnvironmentUtils {
    function _configurePaymentHelper(
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

        address paymentHelper = _readContractsV1(env, chainNames[trueIndex], vars.chainId, "PaymentHelper");

        /// @dev This is where we are making the fireblocks call to perform a configuration update
        PaymentHelper(payable(paymentHelper)).updateRegisterAERC20Params(abi.encode(4, abi.encode(0, "")));

        vm.stopBroadcast();
    }
}

contract TestFireblocksFailure is AbstractTest {
    function testFailure(uint256 env, uint256 selectedChainIndex) external {
        assert(env == 1);
        _setEnvironment(env);

        uint256 trueIndex;
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (TARGET_CHAINS[selectedChainIndex] == chainIds[i]) {
                trueIndex = i;
                break;
            }
        }

        _configurePaymentHelper(env, selectedChainIndex, trueIndex, Cycle.Prod, TARGET_CHAINS);
    }
}
